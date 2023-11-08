all: toplevel

# "make toplevel" compiles the Wampus compiler
toplevel: bin/ast.ml bin/parser.mly bin/scanner.mll bin/toplevel.ml
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

.PHONY: fail-%
fail-%: all $(TESTDIR)/fail-%.wam
	dune exec toplevel < $(TESTDIR)/fail-$*.wam 2> $(TESTDIR)/fail-$*.err