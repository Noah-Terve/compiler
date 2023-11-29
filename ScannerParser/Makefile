MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(abspath $(MAKEFILE_DIR))
EXE_NAME := toplevel.exe
WAMPUS := $(ROOT_DIR)/_build/default/bin/$(EXE_NAME)
COMPILE_SCRIPT := $(ROOT_DIR)/bin/compile.sh
OUTPUT_DIR := $(ROOT_DIR)/out

all: toplevel

# "make toplevel" compiles the Wampus compiler
toplevel: bin/ast.ml bin/parser.mly bin/scanner.mll bin/toplevel.ml bin/codegen.ml bin/semant.ml
	dune build


# "make test" Compiles everything and runs the regression tests
.PHONY: test
test: all testall.sh
	./testall.sh

# "make clean" removes all generated files (not including test outputs)
.PHONY: clean
clean:
	dune clean
	rm testall.log *.diff toplevel.opam *.s *.ll *.out toplevel test.log

# Generate a .out file from a .wam file
%.out: %.wam toplevel
	$(COMPILE_SCRIPT) $< $(OUTPUT_DIR)/$(notdir $<)
	$(OUTPUT_DIR)/$(notdir $<) > $@