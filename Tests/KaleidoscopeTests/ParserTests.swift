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
    private static let emptyTopFunction = Prototype("", [], .function, 30)
    
    func testNumber() throws {
        let code = "3"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                Self.emptyTopFunction,
                .number(3)
            )
        )
    }
    func testId1() throws {
        let code = "fib"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                Self.emptyTopFunction,
                Expr.variable("fib")
            )
        )
    }
    
    func testId2() throws {
        let code = "fib()"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                Self.emptyTopFunction,
                Expr.call("fib", [])
            )
        )
    }
    
    func testId3() throws {
        let code = "fib(a)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                Self.emptyTopFunction,
                Expr.call("fib", [.variable("a")])
            )
        )
    }
    
    func testId4() throws {
        let code = "fib(a, b)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                Self.emptyTopFunction,
                Expr.call("fib", [.variable("a"), .variable("b")])
            )
        )
    }
    
    func testExtern1() throws {
        let code = "extern printd();"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype(
                .init("printd", [], .function, 30)
            )
        )
    }
    
    func testExtern2() throws {
        let code = "extern printd(x);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype(
                .init("printd", ["x"], .function, 30)
            )
        )
    }
    
    func testExtern3() throws {
        let code = "extern printd(x y);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs[0],
            Expr.prototype(
                .init("printd", ["x", "y"], .function, 30)
            )
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
                Self.emptyTopFunction,
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
        (a < ((b + c) - (d * e)))
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
                Self.emptyTopFunction,
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
        (a < ((b - c) + (d * e)))
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
                Self.emptyTopFunction,
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

        let exprs = Parser(input: code).parse()
        print(exprs)
    }
    
    func testComment() {
        let code = "# Compute the x'th fibonacci number."
        
        let tokens = Parser(input: code).parse()
        XCTAssertEqual(tokens.count, 0)
    }
    
    // MARK: Lesson 6
    func testUnary() {
        let code = """
        def unary!(v)
          1;
        """
        
        let exprs = Parser(input: code).parse()
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                .init("unary!", ["v"], .unary, 30),
                .number(1)
            )
        )
    }
    
    func testBinary() {
        let code = """
        def binary| 5 (LHS RHS)
          1;
        """
        
        let exprs = Parser(input: code).parse()
        XCTAssertEqual(
            exprs[0],
            Expr.function(
                .init("binary|", ["LHS", "RHS"], .binary, 5),
                .number(1)
            )
        )
    }
}
