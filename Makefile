all:
	DEBUG=maple/* node lib/main.js

build:
	coffee -o lib			 -c src
	coffee -o test_lib -c test_src

clean:
	rm -rf lib test

.PHONY: test
