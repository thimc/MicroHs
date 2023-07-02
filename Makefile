BIN=bin
BOOTDIR=ghc-boot
OUTDIR=ghc-out
GHCB=ghc -outputdir $(BOOTDIR)
GHCFLAGS=-i -ighc -ilib -i$(BOOTDIR) -hide-all-packages -XNoImplicitPrelude
GHCC=$(GHCB) $(GHCFLAGS)
GHC=ghc
# $(CURDIR) might not be quite right
GHCE=$(GHC) -F -pgmF $(CURDIR)/convert.sh -outputdir $(OUTDIR)
GCC=gcc
.PHONY: all trtest boottest test time example

all:	$(BIN)/eval $(BIN)/uhs

$(BIN)/eval:	src/runtime/eval.c
	@mkdir -p bin
	$(GCC) -Wall -O3 src/runtime/eval.c -o $(BIN)/eval

$(BIN)/uhs:	src/*/*.hs convert.sh
	$(GHCE) -package mtl -isrc -Wall -O src/MicroHs/Main.hs -o $(BIN)/uhs

trtest:	$(BIN)/uhs
	$(BIN)/uhs -ilib Main

a.out:
	rm -rf $(BOOTDIR)
	$(GHCB) -c ghc/Primitives.hs
	$(GHCB) -c ghc/Data/Bool_Type.hs
	$(GHCB) -c ghc/Data/List_Type.hs
	$(GHCC) -c lib/Control/Error.hs
	$(GHCC) -c lib/Data/Bool.hs
	$(GHCC) -c lib/Data/Char.hs
	$(GHCC) -c lib/Data/Either.hs
	$(GHCC) -c lib/Data/Function.hs
	$(GHCC) -c lib/Data/Int.hs
	$(GHCC) -c lib/Data/List.hs
	$(GHCC) -c lib/Data/Maybe.hs
	$(GHCC) -c lib/Data/Tuple.hs
	$(GHCC) -c lib/System/IO.hs
	$(GHCC) -c lib/Text/String.hs
	$(GHCC) -c lib/Prelude.hs
	$(GHCC) -c Main.hs
	$(GHC) $(BOOTDIR)/*.o $(BOOTDIR)/Data/*.o $(BOOTDIR)/System/*.o $(BOOTDIR)/Text/*.o $(BOOTDIR)/Control/*.o

boottest:	a.out
	./a.out

test:	$(BIN)/eval $(BIN)/uhs tests/*.hs
	cd tests; make test

time:	$(BIN)/eval $(BIN)/uhs tests/*.hs
	cd tests; make time

example:	$(BIN)/eval $(BIN)/uhs Example.hs
	$(BIN)/uhs -ilib Example && $(BIN)/eval

clean:
	rm -rf src/*/*.hi src/*/*.o eval Main *.comb *.tmp *~ $(BIN)/* a.out $(BOOTDIR) $(OUTDIR)
	cd tests; make clean
