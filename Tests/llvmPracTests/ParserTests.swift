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
    
    func testNumber() throws {
        let code = "3"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function("", [], .number(3))
        )
    }
    func testId1() throws {
        let code = "fib"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function("", [], Expr.variable("fib"))
        )
    }
    
    func testId2() throws {
        let code = "fib()"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function("", [], Expr.call("fib", []))
        )
    }
    
    func testId3() throws {
        let code = "fib(a)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function("", [], Expr.call("fib", [.variable("a")]))
        )
    }
    
    func testId4() throws {
        let code = "fib(a, b)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function("", [], Expr.call("fib", [.variable("a"), .variable("b")]))
        )
    }
    
    func testExtern1() throws {
        let code = "extern printd();"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype("printd", [])
        )
    }
    
    func testExtern2() throws {
        let code = "extern printd(x);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype("printd", ["x"])
        )
    }
    
    func testExtern3() throws {
        let code = "extern printd(x y);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype("printd", ["x", "y"])
        )
    }
    
    func testIf() throws {
        let code = """
        if x < 3 then
            1
        else
            x
        """
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                "",
                [],
                .if(
                    .binary(.variable("x"), .less, .number(3)),
                    .number(1),
                    .variable("x")
                )
            )
        )
    }
    
    /// <
    /// + -
    /// *
    func testOps() {}
    /**
        a < ((b + c) - (d * e))
          <
         / \
        a   -
           / \
          +   *
         / \ / \
        b  c d  e
     */
    func testOp1() throws {
        let code = "a < b + c - d * e"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                "",
                [],
                .binary(
                    .variable("a"),
                    .less,
                    .binary(
                        .binary(.variable("b"), .plus, .variable("c")),
                        .minus,
                        .binary(.variable("d"), .times, .variable("e"))
                    )
                )
                
            )
        )
    }
    
    /**
        a < ((b - c) + (d * e))
          <
         / \
        a   +
           / \
          -   *
         / \ / \
        b  c d  e
     */
    func testOp2() throws {
        let code = "a < b - c + d * e"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                "",
                [],
                .binary(
                    .variable("a"),
                    .less,
                    .binary(
                        .binary(.variable("b"), .minus, .variable("c")),
                        .plus,
                        .binary(.variable("d"), .times, .variable("e"))
                    )
                )
                
            )
        )
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
