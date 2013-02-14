SRC = $(wildcard *.coffee)
LIB = $(SRC:%.coffee=lib/%.js)

all: test

test: build build-tests
	mocha-phantomjs runner.html

build:
	$(MAKE) -C .. build

build-tests: $(LIB)

build-all: build build-tests

clean:
	rm -f $(LIB)

lib/%.js: %.coffee
	coffee -bcp $< > $@
