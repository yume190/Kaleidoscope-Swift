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

Parser.init(input: "4+5").parse().forEach {$0.codeGen()?.dump()}
Parser.init(input: "def foo(a b) a*a + 2*a*b + b*b;").parse().forEach {$0.codeGen()?.dump()}
