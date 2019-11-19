//
//  ParserTests.swift
//  llvmPracTests
//
//  Created by 林煒峻 on 2019/11/18.
//

import XCTest
import class Foundation.Bundle
@testable import Lexer
@testable import AST
@testable import Token
@testable import Parser

final class ParserTests: XCTestCase {
//    func testKeyword_def() throws {
//        let code = "def"
//        let exprs = Parser(input: code).parse()
//        XCTAssertEqual(exprs[0], Expr.)
//    }
    
    func testNumber() throws {
        let code = "3"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(exprs[0], Expr.number(3))
    }
    func testId1() throws {
        let code = "fib"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(exprs[0], Expr.variable("fib"))
    }
    
    func testId2() throws {
        let code = "fib()"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(exprs[0], Expr.call("fib", []))
    }
    
    func testId3() throws {
        let code = "fib(a)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(exprs[0], Expr.call("fib", []))
    }
    
    func testId4() throws {
        let code = "fib(a, b)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(exprs[0], Expr.call("fib", []))
    }
    
    func testIdentifier() throws {
        let code = """
        def fib(x)
          if x < 3 then
            1
          else
            fib(x-1)+fib(x-2)

        fib(40)
        """

//        let tokens = Parser(
//        XCTAssertEqual(tokens.count, 29)
//        XCTAssertEqual(tokens[0], Token.keyword(.def))
//        XCTAssertEqual(tokens[28], Token.mark(.closeParen))
    }
    
    func testComment() {
        let code = "# Compute the x'th fibonacci number."

        let tokens = Lexer(input: code).lex()
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0], Token.comment("# Compute the x'th fibonacci number."))
//
//        XCTAssertEqual failed: (
//        "comment("# Compute the x\'th fibonacci number.")") is not equal to (
//        "comment(" Compute the x\'th fibonacci number.")")
    }

//    static var allTests = [
//        ("testFullCode1", testFullCode1),
//        ("testComment", testComment)
//    ]
}
