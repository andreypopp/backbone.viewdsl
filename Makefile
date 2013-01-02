SRC = $(wildcard *.coffee)
LIB = $(SRC:%.coffee=%.js)

all: build

build: $(LIB)

clean:
	@rm -f *.js

test:
	@$(MAKE) -Ctests test

%.js: %.coffee
	@coffee -bcp $< > $@

