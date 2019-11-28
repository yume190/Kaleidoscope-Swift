import Lexer
import AST
import Parser
import IRGen
import LLVM

let code = """
def fib(x)
  if x < 3 then
    1
  else
    fib(x-1)+fib(x-2)

fib(40)
"""

//print(Lexer(input: code).lex().map{$0.description}.joined(separator: "\n"))
//print("\n------------------------\n")
//print(Parser(input: code).parse().map{$0.description}.joined(separator: "\n"))
//print(Parser(input: code).parse())

func dump(code: String) {
  Parser(input: code).parse().forEach {$0.codeGen()?.dump()}
}

dump(code: "4+5")
dump(code: "def foo(a b) a*a + 2*a*b + b*b;")

/// Problem: (x + 3) * 2 
/// Answer: tmp = x + 3, result = tmp*tmp;
/// tips:
///   * reassociation of expressions(to make the add’s lexically identical)
//    * Common Subexpression Elimination (CSE)
dump(code: "def test(x) (1+2+x)*(x+(1+2));")
// define double @test(double %x) {
// entry:
//         %addtmp = fadd double 3.000000e+00, %x
//         %addtmp1 = fadd double %x, 3.000000e+00
//         %multmp = fmul double %addtmp, %addtmp1
//         ret double %multmp
// }

isAddOptimizerPass = true
dump(code: "def test(x) (1+2+x)*(x+(1+2));")
// define double @test(double %x) {
// entry:
//         %addtmp = fadd double %x, 3.000000e+00
//         %multmp = fmul double %addtmp, %addtmp
//         ret double %multmp
// }