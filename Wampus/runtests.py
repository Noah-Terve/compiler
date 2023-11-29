#!/usr/local/bin/python3

# TODO: Implement more verbose logging
# TODO: Use "keep" flag to keep intermediate files. It should also be used during the "exec" stage to generate intermediate files instead piping everything in a chain.

# Imports
import os
import sys
from glob import glob
import subprocess
import argparse
import typing

# Inspired by https://stackoverflow.com/questions/287871/print-in-terminal-with-colors
class Colors:
    def __init__(self):
        pass

    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# Possible stages of the compiler that can be tested
# 1. Scanner & Parser: the AST (reference output in test-*.ast)
# 2. Semantic Analysis: the SAST (reference output in test-*.sast)
# 3. Code Generation: the LLVM IR (reference output in test-*.ll)
# 4. Optimization: the optimized LLVM IR (reference output in test-*.opt.ll)
# 5. Execution: the output of the program (reference output in test-*.out)

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

# Set the path to the WAMPUS executable
WAMPUS = "toplevel"
WAMPUS_EXE = f"{SCRIPT_DIR}/_build/default/bin/" + WAMPUS + ".exe"
# WAMPUS = "_build/wampus.native"
# e.g. Can be run with `dune exec $WAMPUS testfile.wam` in the command line

TEST_DIR = "test/"
STAGE_DIRS = {
    "ast": TEST_DIR + "ast/",
    "sast": TEST_DIR + "sast/",
    "llvm": TEST_DIR + "llvm/",
    "opt": TEST_DIR + "opt/",
    "exec": TEST_DIR + "exec/"
}
OUTPUT_DIR = f"{SCRIPT_DIR}/out"

# Set a time limit for all operations
# Note: ulimit -t 30 is not directly translatable to Python
# You may need to set system resource limits using other means.

LOGFILE = "test.log"

error = 0
globalerror = 0
keep = False
promote = False
logger = None
verbose = False
mode = "exec"

def get_mode(args: argparse.Namespace) -> str:
    """Return the mode of the compiler to test"""
    if args.ast:
        return "ast"
    elif args.sast:
        return "sast"
    elif args.llvm:
        return "llvm"
    elif args.opt:
        return "opt"
    elif args.exec:
        return "exec"
    else:
        raise ValueError("Invalid mode")


def parse_command_line() -> argparse.Namespace:
    """
    Parse command line arguments for testing the WAMPUS compiler.

    Returns:
        argparse.Namespace: The parsed command line arguments.
    """
    parser = argparse.ArgumentParser(description='Test the WAMPUS compiler. \n' +
                                     'Files to test can be specified on the command line. If no files are specified, ' +
                                     'all output files in the tests/exec_output directory are tested.' +
                                     '\nBy default, the output of running the program is tested. ')
    parser.add_argument('-k', '--keep', action='store_true', help='Keep intermediate files')
    parser.add_argument('files', metavar='file', type=str, nargs='*', help='Files to test')
    parser.add_argument('--promote', action='store_true', help='For tests ran, promote test outputs to be the new reference outputs')
    parser.add_argument('--no-log', action='store_true', help='Do not log test results (loging is on by default)')
    parser.add_argument('--log-file', type=str, default=LOGFILE, help='Log file (default: test.log)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Print more verbose output')

    # Create a mutually exclusive group for the different stages of the compiler
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-a', '--ast', action='store_true', help='Test the AST')
    group.add_argument('-d', '--detemp', action='store_true', help='Test the DETEMPLATE')
    group.add_argument('-s', '--sast', action='store_true', help='Test the SAST')
    group.add_argument('-l', '--llvm', action='store_true', help='Test the LLVM IR')
    group.add_argument('--opt', action='store_true', help='Test the optimized LLVM IR')
    group.add_argument('-c', '--exec', action='store_true', help='(Default) Test the output of running compiled programs')

    args = parser.parse_args()

    if not any([args.ast, args.sast, args.llvm, args.opt, args.exec]):
        args.exec = True

    global mode
    mode = get_mode(args)

    if args.verbose:
        global verbose
        verbose = True

    if args.promote:
        global promote
        promote = True

    if args.keep:
        global keep
        keep = True

    return args


def check_files(files) -> typing.List[str]:
    """Return a list of files to test and the corresponding reference files, for only those that exist
    
    If a file or reference file does not exist, it is not included in the list of files to test.

    args:
        files: list of files to test
    returns files_to_test: existing files to test
    """
    print(f"Checking:\n{files}", file=sys.stderr)
    return [file for file in files if os.path.isfile(file)]


def get_files_to_test(args: argparse.Namespace) -> typing.Tuple[typing.List[str], typing.List[str]]:
    """Return a list of files to test and files that are supposed to fail

    If tests are specified on the command line, use those

    If no tests are specified on the command line, find all test and output files in the tests/exec_output directory.

    Tests can appear in subdirectories of any stage directory.
    """

    mode = get_mode(args)

    files = []
    if files:
        files = check_files(files)
    else:
        # Any subdirectory of STAGE_DIRS[mode]
        files.extend(glob(STAGE_DIRS[mode] + "**/*.wam", recursive=True))

    test_files = [file for file in files if os.path.basename(file).startswith("test-")]
    fail_files = [file for file in files if os.path.basename(file).startswith("fail-")]

    if verbose:
        print(f"Found passing tests: {test_files}")
        print(f"Found failing tests: {fail_files}")

    return test_files, fail_files


def generate_output_of_cmd(cmd: typing.List[str]) -> tuple[str, str, bool]:
    """Generate the output for the given file using the given command.
    
    Returns a tuple of the standard output, standard error and a boolean indicating whether the
    command succeeded.
    """
    print(' '.join(cmd), file=logger)

    try:
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errout = p.communicate()
        return output.decode('utf-8'), errout.decode('utf-8'), p.returncode == 0
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8'), e.stderr.decode('utf-8'), False


def generate_output(file: str, testname: str) -> tuple[str, str, bool, typing.List[str]]:
    """Run the appropriate stage of the compiler

    returns a tuple containing standard output, error output, a boolean indicating whether there was
    an error, and a list of generated files
    """
    success = False

    generated_files = []

    match mode:
        case "ast":
            cmd = [WAMPUS_EXE, "-a", file]
            output, errout, success = generate_output_of_cmd(cmd)
        case "detemp":
            cmd = [WAMPUS_EXE, "-d", file]
            output, errout, success = generate_output_of_cmd(cmd)
        case "sast":
            cmd = [WAMPUS_EXE, "-s", file]
            output, errout, success = generate_output_of_cmd(cmd)
        case "llvm":
            cmd = [WAMPUS_EXE, "-l", file]
            output, errout, success = generate_output_of_cmd(cmd)
        case "opt":
            raise NotImplementedError
        case "exec":
            # Compile the wampus file into an executable
            cmd1 = [f"{SCRIPT_DIR}/bin/compile.sh", file, f"{OUTPUT_DIR}/{testname}.exe"]
            output, errout, success = generate_output_of_cmd(cmd1)

            print(f"Output: {output}", file=logger)
            print(f"Error output: {errout}", file=logger)

            generated_files.extend([f"{OUTPUT_DIR}/{testname}.{ext}" for ext in ["ll", "s", "exe"]])

            if success:
                # Run the executable
                cmd2 = [f"{OUTPUT_DIR}/{testname}.exe"]
                output, errout, success = generate_output_of_cmd(cmd2)

    return output, errout, success, generated_files


def get_diff(file1: str, file2: str) -> tuple[str, bool]:
    """Return the diff of two files"""
    cmd = ["diff", "-b", file1, file2]
    try:
        return subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode('utf-8'), True
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8'), False


def promote_output(ref_path: str, output: str) -> None:
    """
    Writes the given output to the reference file at the specified path.

    Args:
        ref_path (str): The path to the reference file.
        output (str): The output to write to the reference file.

    Returns:
        None
    """
    with open(ref_path, "w", encoding="utf-8") as ref_file:
        ref_file.write(output)


def run_test(file: str, testname: str) -> bool:
    """Run a single test, generating its output and comparing it to the reference output."""
    print(f"\n###### testing {testname}", file=logger)

    ref_path = os.path.splitext(file)[0] + ".out"

    output, output_error, raised_error, generated_files = generate_output(file, testname)

    if raised_error:
        print(f"###### FAILED: {testname} raised an error", file=logger)

    with open(f"{OUTPUT_DIR}/{testname}.out", "w", encoding="utf-8") as output_file:
        output_file.write(output)
        output_file_path = output_file.name
        generated_files.append(output_file_path)

    if promote:
        promote_output(ref_path, output)
        if not keep:
            for file in generated_files:
                os.remove(file)
        return True
    
    if not os.path.isfile(ref_path):
        print(f"###### FAILED: {ref_path} does not exist", file=logger)
        return False
    
    # with open(ref_path, "r", encoding="utf-8") as ref_file:
    #     ref_output = ref_file.read()

    diff, success = get_diff(ref_path, output_file_path)
    with open(f"{OUTPUT_DIR}/{testname}.diff", "w", encoding="utf-8") as diff_file:
        diff_file.write(diff)
        generated_files.append(diff_file.name)

    if success:
        print(f"##### PASSED: {testname}", file=logger)
        if not keep:
            for file in generated_files:
                os.remove(file)
        return True
    
    print(f"###### FAILED: {testname}", file=logger)

    return False


def run_fail(file: str, testname: str) -> bool:
    """Run the test expecting it to fail."""
    print(f"\n###### testing {testname}", file=logger)

    ref_path = os.path.splitext(file)[0] + ".err"

    output, output_error, raised_error, generated_files = generate_output(file, testname)

    if not raised_error:
        print(f"###### FAILED: {testname} did not raise an error", file=logger)
        return False
    
    with open(f"{OUTPUT_DIR}/{testname}.err", "w", encoding="utf-8") as output_file:
        output_file.write(output_error)
        output_file_path = output_file.name
        generated_files.append(output_file_path)

    if promote:
        promote_output(ref_path, output_error)
        if not keep:
            for file in generated_files:
                os.remove(file)
        return True
    
    if not os.path.isfile(ref_path):
        print(f"###### FAILED: {ref_path} does not exist", file=logger)
        return False
    
    # with open(ref_path, "r", encoding="utf-8") as ref_file:
    #     ref_output = ref_file.read()
    
    diff, success = get_diff(ref_path, output_file_path)
    with open(f"{OUTPUT_DIR}/{testname}.diff", "w", encoding="utf-8") as diff_file:
        diff_file.write(diff)
        generated_files.append(diff_file.name)

    if success:
        print(f"##### PASSED: {testname}", file=logger)
        if not keep:
            for file in generated_files:
                os.remove(file)
        return True
    
    print(f"###### FAILED: {testname}", file=logger)

    return False




def main():
    global logger # Use global variable so it doesn't need to be passed around
    logger = open(LOGFILE, "w", encoding="utf-8")

    args = parse_command_line()
    print(args, file=logger)

    test_files, fail_files = get_files_to_test(args)
    print(f"Found {len(test_files)} test(s) and {len(fail_files)} failing test(s)", file=logger)
    print(f"{test_files}\n{fail_files}", file=logger)


    for test_file in test_files:
        testname = os.path.basename(test_file).removesuffix(".wam")
        print(f"{testname}...", end="")
        success = run_test(test_file, testname)
        if success:
            print(f"{Colors.OKGREEN}PASSED{Colors.ENDC}")
        else:
            print(f"{Colors.FAIL}FAILED{Colors.ENDC}")

    for fail_file in fail_files:
        testname = os.path.basename(fail_file).removesuffix(".wam")
        print(f"{testname}...", end="")
        success = run_fail(fail_file, testname)
        if success:
            print(f"{Colors.OKGREEN}PASSED{Colors.ENDC}")
        else:
            print(f"{Colors.FAIL}FAILED{Colors.ENDC}")


    # close log file
    logger.close()

    exit(1)

    # if args.keep:
    #     keep = True

    # for file, ref_file in zip(files, ref_files):
    #     testname = os.path.basename(file).replace('.wam', '')
    #     print(f"File \"{file}\"...", end="", file=sys.stderr)
    #     run_test(args, file, ref_file, testname)

    # log_file.close()
    
    


if __name__ == "__main__":
    main()

    # Parse command-line arguments
    

    # print args
    # print(args)

    # if args:
    #     files = args.files
    #     exit(0)
    # else:
    #     # Find all test-*.wam and fail-*.wam files in tests/
    #     # You may need to replace this with the appropriate path to your test files.
    #     files = [
    #         os.path.join(root, filename)
    #         for root, dirs, filenames in os.walk("tests")
    #         for filename in filenames
    #         if filename.startswith("test-") or filename.startswith("fail-")
    #     ]
    #     print(files)
    exit(0)

    # for file in files:
    #     if "test-" in file:
    #         check(file)
    #     elif "fail-" in file:
    #         check_fail(file)
    #     else:
    #         print(f"unknown file type {file}")
    #         globalerror = 1

    exit(globalerror)