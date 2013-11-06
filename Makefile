# XXX Not using submdules yet. Need to add them.

.PHONY: test
EXT = \
	ext/bashplus/lib \
	ext/test-tap-bash/lib \

.PHONY: test
# test: $(EXT)
test:
	prove $(PROVEOPT:%=% )test/

$(EXT):
	git submodule update --init

clean:
	rm -fr xyz test/*-cog
