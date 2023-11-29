MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(abspath $(MAKEFILE_DIR))
EXE_NAME := toplevel.exe
WAMPUS := $(ROOT_DIR)/_build/default/bin/$(EXE_NAME)
COMPILE_SCRIPT := $(ROOT_DIR)/bin/compile.sh
OUTPUT_DIR := $(ROOT_DIR)/out

temp:
	@echo $(MAKEFILE_DIR)
	@echo $(ROOT_DIR)
	@echo $(WAMPUS)
	@echo $(COMPILE_SCRIPT)

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
	rm -rf testall.log *.diff toplevel.opam
	rm *.s
	rm *.ll
	rm *.out

# Generate the output of a given test
# The test is in the form of a full path to a .wam file
# This rule will generate a .out file in the same directory
# The .out file contains the output of running the test, after compiling it
# with the Wampus compiler
%.out: %.wam toplevel
	$(COMPILE_SCRIPT) $< $(OUTPUT_DIR)/$(notdir $<)
	$(OUTPUT_DIR)/$(notdir $<) > $@