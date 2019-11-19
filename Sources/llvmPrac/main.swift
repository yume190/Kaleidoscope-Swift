import Lexer
import AST
import Parser

let code = """
def fib(x)
  if x < 3 then
    1
  else
    fib(x-1)+fib(x-2)

fib(40)
"""

print(Lexer(input: code).lex().map{$0.description}.joined(separator: "\n"))
print("\n------------------------\n")
print(Parser(input: code).parse().map{$0.description}.joined(separator: "\n"))
