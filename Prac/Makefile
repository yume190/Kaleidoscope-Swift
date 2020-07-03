graph:
	llvm-as < t.ll | opt -analyze -view-cfg

.PHONY: build
build:
	@swift build -c release

average.o: build average.k
	@swift run -c release kaleidoscope average.k -o average.o

main: main.swift average.o
	@swiftc average.o main.swift -o main

run: main
	@./main