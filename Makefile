# Author: Neil Powers, Noah Tervalon

MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(abspath $(MAKEFILE_DIR))
EXE_NAME := wampus.exe
WAMPUS := $(ROOT_DIR)/_build/default/bin/$(EXE_NAME)
COMPILE_SCRIPT := $(ROOT_DIR)/compile.sh
OUTPUT_DIR := $(ROOT_DIR)/out

CC = gcc
CFLAGS = -Wall -Wextra -O2

all: toplevel

# test-list: bin/list.c tests/lists/test-list.c 
# 	$(CC) $(CFLAGS) -Ibin -o $@ $^

# .PHONY:	lists

# lists: test-list
# 	./test-list

all: toplevel

# "make toplevel" compiles the Wampus compiler
toplevel: bin/ast.ml bin/parser.mly bin/scanner.mll bin/toplevel.ml bin/codegen.ml bin/semant.ml list.o
	dune build

list.o:
	$(CC) $(CFLAGS) -c -o bin/list.o bin/list.c

# %.o:# bin/%.c
# 	$(CC) $(CFLAGS) -c -o bin/$@ bin/$*.c

# "make test" Compiles everything and runs the regression tests
.PHONY: test
test: all testall.sh
	./testall.sh

# "make clean" removes all generated files (not including test outputs)
.PHONY: clean
clean:
	dune clean
	rm testall.log *.diff toplevel.opam *.s *.out toplevel test.log

# Generate a .out file from a .wam file
%.out: %.wam toplevel
	$(COMPILE_SCRIPT) $< $(OUTPUT_DIR)/$(notdir $<)
	$(OUTPUT_DIR)/$(notdir $<) > $@

# Generate a .out file from a .wam file
%.err: %.wam toplevel
	$(COMPILE_SCRIPT) $< $(OUTPUT_DIR)/$(notdir $<)
	$(OUTPUT_DIR)/$(notdir $<) > $@