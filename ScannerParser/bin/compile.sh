#!/bin/bash

# Compile a wampus program to an executable, generating any intermediate files
# in the process. All generated files are placed in the same directory as the
# output executable.
# Usage: compile.sh <wampus source file> <output executable>

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR="$(dirname "$SCRIPT_DIR")"

LLC="llc"
CC="cc"
WAMPUS="$HOME_DIR/_build/default/bin/toplevel.exe"

# usage function
usage() {
    echo "Usage: compile.sh <wampus source file> <output executable>"
    exit 1
}


# set time limit for all operations
ulimit -t 30

# check arguments
if [ $# -ne 2 ]; then
    usage
fi

wam_file="$1"
exe_file="$2"

name=$(basename "${wam_file%.*}")

TARGET_DIR="$(dirname "$exe_file")"

# Make the wampus compiler
echo "Building compiler:"
make -C "$HOME_DIR"
echo ""

# Compile the wampus file to llvm
echo "Compiling to llvm:"
echo "$WAMPUS $wam_file > $TARGET_DIR/$name.ll"
"$WAMPUS" "$wam_file" > "$TARGET_DIR/$name.ll"
echo ""

# Compile the llvm file to assembly
echo "Compiling llvm to assembly:"
echo "$LLC -relocation-model=pic $TARGET_DIR/$name.ll -o $TARGET_DIR/$name.s"
"$LLC" -relocation-model=pic "$TARGET_DIR/$name.ll" -o "$TARGET_DIR/$name.s"
echo ""

# Compile the assembly file to an executable
echo "Compiling assembly into an executable:"
echo "$CC -O2 $TARGET_DIR/$name.s -o $exe_file"
"$CC" -O2 "$TARGET_DIR/$name.s" -o "$exe_file"
echo ""
echo "Run your the program with:"
echo "./$exe_file"