SRC = $(wildcard *.coffee)
LIB = $(SRC:%.coffee=%.js)

all: build

build: $(LIB)

clean:
	rm -f *.js

test:
	$(MAKE) -Ctests test

watch-test:
	watch -n 1 make -Ctests build build-tests

%.js: %.coffee
	coffee -bcp $< > $@

publish:
	git push
	git push --tags
	npm publish

docs::
	$(MAKE) -Cdocs
