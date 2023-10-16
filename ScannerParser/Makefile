

# Files included for testing
TESTS = id-expr func struct\
        string1 string2 string3
FAILS = unknown-character \
        string1 string2
TESTDIR = tests


all: toplevel

# "make toplevel" compiles the Wampus compiler
toplevel: bin/ast.ml bin/parser.mly bin/scanner.mll bin/toplevel.ml
	dune build


# "make test" Compiles everything and runs the regression tests
.PHONY: test
test: all testall.sh
	./testall.sh

# Generate a specific test output

# "make test-<ID>" generates the expected output for the test with name ID.

.PHONY: test-%
test-%: all $(TESTDIR)/test-%.wam
	dune exec toplevel < $(TESTDIR)/test-$*.wam > $(TESTDIR)/test-$*.out

# "make fail-<ID>" generates the expected output for the failing test with name
# ID.

.PHONY: fail-%
fail-%: all $(TESTDIR)/fail-%.wam
	dune exec toplevel < $(TESTDIR)/fail-$*.wam 2> $(TESTDIR)/fail-$*.err

# "make clean" removes all generated files (not including test outputs)
.PHONY: clean
clean:
	dune clean
	rm -rf testall.log *.diff toplevel.opam