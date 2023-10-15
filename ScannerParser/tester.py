# This program will run tests for the Wampus compiler.
# 
# Options:
# You can specify which stage. Only the first stage specified will be run.
#  -a, --all: Run all tests.
#  -p, --parser: Run the parser tests.
#  -s, --scanner: Run the scanner tests.
#
# Can be specified to run a subset of tests within a stage of the compiler:
#  -d <directory>, --directory <directory>: Run all tests in a specific directory.
#                   The directory is decided based on the option specified.
#  -f <file>, --file <file>: Run a specific test file (path in tests/... is required).
# 
# Usage: python tester.py (-a | -p | -s) [-d <directory> | -f <file>]

is_working = True

if not is_working:
    print("This is still a work in progress. Please check back later.")
    sys.exit()

import sys
import os
import argparse
import subprocess

# Location of tester.py is the root of the project.
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
WAMPUS = os.path.join(ROOT_DIR, "_build", "wampus.native")

TESTS_DIR = os.path.join(ROOT_DIR, "tests")

# Directories for tests of different stages of the compiler.
PARSER_DIR = os.path.join(TESTS_DIR, "parser_tests")
SCANNER_DIR = os.path.join(TESTS_DIR, "scanner_tests")

def parse_args():
    parser = argparse.ArgumentParser(description="Run tests for the Wampus compiler.")
    parser.add_argument("-a", "--all", action="store_true", help="Run all tests.")
    parser.add_argument("-p", "--parser", action="store_true", help="Run the parser tests.")
    parser.add_argument("-s", "--scanner", action="store_true", help="Run the scanner tests.")
    parser.add_argument("-d", "--directory", type=str, help="Run all tests in a specific directory.")
    parser.add_argument("-f", "--file", type=str, help="Run a specific test file.")

    args = parser.parse_args()

    if args.all:
        args.parser = True
        args.scanner = True

    return args

def run_file_test(file_path):
    print("Running test: " + file_path)
    subprocess.run("dune exec " + WAMPUS + " " + file_path, shell=True, check=True)
    

parse_args()



