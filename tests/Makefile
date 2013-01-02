SRC = $(wildcard *.coffee)
LIB = $(SRC:%.coffee=lib/%.js)

all: test

test: build build-tests
	mocha-phantomjs runner.html

build:
	$(MAKE) -qC.. build

build-tests: $(LIB)

lib/%.js: %.coffee
	coffee -bcp $< > $@

