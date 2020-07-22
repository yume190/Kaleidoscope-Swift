graph:
	llvm-as < t.ll | opt -analyze -view-cfg

.PHONY: build
build:
	@swift build -c release

# @swift run -c release kaleidoscope main.k -o main.ko
%.ko : %.k build
	@swift run -c release kaleidoscope $< -o $@

# 	@swiftc main.ko main.swift -o main
%.so: %.swift %.ko
	@swiftc $*.ko $< -o $@

# @./main.so
%: %.so
	@./$@.so
