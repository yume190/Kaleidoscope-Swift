# Kaleidoscope-Swift

![Swift](https://github.com/yume190/Kaleidoscope-Swift/workflows/Swift/badge.svg)

---

## Resouces

 * [My First Language Frontend with LLVM Tutorial](https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/index.html)
 * [qyz777/Kaleidoscope](https://github.com/qyz777/Kaleidoscope)
 * [JIT.h](https://github.com/llvm-mirror/llvm/blob/master/examples/Kaleidoscope/include/KaleidoscopeJIT.h)

## Install Dependency

``` sh
# Install llvm
brew install llvm@8
export PATH="/usr/local/opt/llvm@8/bin:$PATH"

# check llvm-config exist
llvm-config

# use llvm-config to generate pc /usr/local/lib/pkgconfig/cllvm.pc
git clone https://github.com/llvm-swift/LLVMSwift
swift LLVMSwift/utils/make-pkgconfig.swift
```

## Compile Code

> swift run -c release kaleidoscope code.k -o code.o

## Practice Code

``` sh
# brew install make
cd Prac
make lesson6
make main
```

---

## Choose target

``` sh
clang --version | grep
Target: x86_64-apple-darwin19.5.0

llvm-as < /dev/null | llc -march=x86 -mattr=help
Available CPUs for this target:

  amdfam10       - Select the amdfam10 processor.
  athlon         - Select the athlon processor.
  ...

Available features for this target:

  16bit-mode                    - 16-bit mode (i8086).
  32bit-mode                    - 32-bit mode (80386).
  3dnow                         - Enable 3DNow! instructions.
  ...

```