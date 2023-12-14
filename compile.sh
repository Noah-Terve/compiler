#!/bin/bash

# Author: Neil Powers
# Minor edits for readability by: Noah Tervalon
# Compile a wampus program to an executable, generating any intermediate files
# in the process. All generated files are placed in the same directory as the
# output executable.
# Usage: compile.sh <wampus source file> <output executable>

# if any command fails or any unset variable is used, exit immediately
set -euo pipefail

# get the directory of this script, regardless of where it is called from
# Info: BASH_SOURCE[0] is the path to this script. dirname strips the filename
#       from the path, leaving the directory. We cd into that directory and
#       pwd to get the absolute path.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# location of our compilers (llc, cc, and wampus).
LLC="llc"
CC="cc"
WAMPUS="$SCRIPT_DIR/_build/default/bin/toplevel.exe"

# usage function
usage() {
    echo "Usage: compile.sh <wampus source file> <output executable>"
    exit 1
}

# verify llc and cc are in the path
if ! command -v "$LLC" >/dev/null 2>&1; then
    echo "Error: $LLC not found in path"
    exit 1
fi
if ! command -v "$CC" >/dev/null 2>&1; then
    echo "Error: $CC not found in path"
    exit 1
fi


# set time limit for all operations
ulimit -t 30

# check for correct number of arguments (input and output file)
if [ $# -ne 2 ]; then
    usage
fi

wam_file="$1"
exe_file="$2"

name=$(basename "${wam_file%.*}")

TARGET_DIR="$(dirname "$exe_file")"

# Make the wampus compiler
echo "Building compiler:"
make -C "$SCRIPT_DIR"
echo ""

make -C "$SCRIPT_DIR" list.o

# Compile the wampus file to llvm
echo "Compiling to llvm:"
echo "$WAMPUS $wam_file > $TARGET_DIR/$name.ll"
"$WAMPUS" "$wam_file" > "$TARGET_DIR/$name.ll"
echo ""

# Compile the llvm file to assembly
# Info: -relocation-model=pic is used to make the assembly position independent
#       so that it can be linked into an executable
echo "Compiling llvm to assembly:"
echo "$LLC -relocation-model=pic $TARGET_DIR/$name.ll -o $TARGET_DIR/$name.s"
"$LLC" -relocation-model=pic "$TARGET_DIR/$name.ll" -o "$TARGET_DIR/$name.s"
echo ""

# Compile the assembly file to an executable
echo "Compiling assembly into an executable:"
echo "$CC -O2 $TARGET_DIR/$name.s list.o -o $exe_file"
"$CC" -O2 "$TARGET_DIR/$name.s" "$SCRIPT_DIR/bin/list.o" -o "$exe_file"
echo ""
echo "Run your the program with:"
echo "./$exe_file"