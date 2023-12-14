#!/bin/sh

# Author: Neil Powers
# Regression testing script for Wampus toplevel
# Step through a list of files
#  Compile, run, and check the output of each expected-to-work test
#  Compile and check the error of each expected-to-fail test

# Try "_build/wampus.native" if ocamlbuild was unable to create a symbolic link.
WAMPUS="toplevel"
LLC="llc"
CC="cc"
#WAMPUS="_build/wampus.native"

# Set time limit for all operations
ulimit -t 30

OUTPUT_DIR="out"
mkdir -p $OUTPUT_DIR

globallog=testall.log
rm -f $globallog
error=0
globalerror=0

keep=0

Usage() {
    echo "Usage: testall.sh [options] [.wam files]"
    echo "-k    Keep intermediate files"
    echo "-h    Print this help"
    exit 1
}

SignalError() {
    if [ $error -eq 0 ] ; then
	echo "FAILED"
	error=1
    fi
    echo "  $1"
}

# Compare <outfile> <reffile> <difffile>
# Compares the outfile with reffile.  Differences, if any, written to difffile
Compare() {
    generatedfiles="$generatedfiles $3"
    echo diff -b $1 $2 ">" $3 1>&2
    diff -b "$1" "$2" > "$3" 2>&1 || {
	SignalError "$1 differs"
	echo "FAILED $1 differs from $2" 1>&2
    }
}

# Run <args>
# Report the command, run it, and report any errors
Run() {
    echo $* 1>&2
    eval $* || {
	SignalError "$1 failed on $*"
	return 1
    }
}

# RunFail <args>
# Report the command, run it, and expect an error
RunFail() {
    echo $* 1>&2
    eval $* && {
	SignalError "failed: $* did not report an error"
	return 1
    }
    return 0
}

Check() {
    error=0
    basename=`echo $1 | sed 's/.*\\///
                             s/.wam//'`
    reffile=`echo $1 | sed 's/.wam$//'`
    basedir="`echo $1 | sed 's/\/[^\/]*$//'`/."

    echo -n "$basename..."

    echo 1>&2
    echo "###### Testing $basename" 1>&2

    generatedfiles=""

    output_path="$OUTPUT_DIR/$basename"

    generatedfiles="$generatedfiles ${output_path}.ll ${output_path}.s ${output_path}.exe ${output_path}.out" &&
    Run "dune exec $WAMPUS" "$1" ">" "${output_path}.ll" &&
    Run "$LLC" "-relocation-model=pic" "${output_path}.ll" ">" "${output_path}.s" &&
    Run "$CC" "-o" "${output_path}.exe" "${output_path}.s" &&
    Run "./${output_path}.exe" > "${output_path}.out" &&
    Compare ${output_path}.out ${reffile}.out ${output_path}.diff

    # Report the status and clean up the generated files

    if [ $error -eq 0 ] ; then
	if [ $keep -eq 0 ] ; then
	    rm -f $generatedfiles
	fi
	echo "OK"
	echo "###### SUCCESS" 1>&2
    else
	echo "###### FAILED" 1>&2
	globalerror=$error
    fi
}

CheckFail() {
    error=0
    basename=`echo $1 | sed 's/.*\\///
                             s/.wam//'`
    reffile=`echo $1 | sed 's/.wam$//'`
    basedir="`echo $1 | sed 's/\/[^\/]*$//'`/."

    echo -n "$basename..."

    echo 1>&2
    echo "###### Testing $basename" 1>&2

    generatedfiles=""

    output_path="$OUTPUT_DIR/$basename"

    generatedfiles="$generatedfiles ${output_path}.err ${output_path}.diff" &&
    RunFail "dune exec $WAMPUS" "<" $1 "2>" "${output_path}.err" ">>" $globallog &&
    Compare ${output_path}.err ${reffile}.err ${output_path}.diff

    # Report the status and clean up the generated files

    if [ $error -eq 0 ] ; then
	if [ $keep -eq 0 ] ; then
	    rm -f $generatedfiles
	fi
	echo "OK"
	echo "###### SUCCESS" 1>&2
    else
	echo "###### FAILED" 1>&2
	globalerror=$error
    fi
}

while getopts kdpsh c; do
    case $c in
	k) # Keep intermediate files
	    keep=1
	    ;;
	h) # Help
	    Usage
	    ;;
    esac
done

shift `expr $OPTIND - 1`

if [ $# -ge 1 ]
then
    files=$@
else
    # Find all test-*.wam and fail-*.wam files in tests/
    # files="tests/exec/test-*.wam tests/exec/fail-*.wam"

    # Files include any test-*.wam and fail-*.wam file in tests/ or any
    # of its subdirectories.
    files=`find tests/exec -name 'test-*.wam' -o -name 'fail-*.wam'`
fi

for file in $files
do
    case $file in
	*test-*)
	    Check $file 2>> $globallog
	    ;;
	*fail-*)
	    CheckFail $file 2>> $globallog
	    ;;
	*)
	    echo "unknown file type $file"
	    globalerror=1
	    ;;
    esac
done

exit $globalerror
