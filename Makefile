all: build run

run:
	DEBUG=maple/* node lib/main.js

build:
	coffee -o lib	 -c src
	coffee -o test -c test_src

clean:
	rm -rf lib test

test: build run-tests

run-tests:
	mocha

.PHONY: test
