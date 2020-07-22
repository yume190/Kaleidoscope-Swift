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
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    .number(3)
                )
            ]
        )
    }
    func testId1() throws {
        let code = "fib"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    Expr.variable("fib")
                )
            ]
        )
    }
    
    func testId2() throws {
        let code = "fib()"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    Expr.call("fib", [])
                )
            ]
        )
    }
    
    func testId3() throws {
        let code = "fib(a)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    Expr.call("fib", [.variable("a")])
                )
            ]
        )
    }
    
    func testId4() throws {
        let code = "fib(a, b)"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    Expr.call("fib", [.variable("a"), .variable("b")])
                )
            ]
        )
    }
    
    func testExtern1() throws {
        let code = "extern printd();"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.prototype(
                    .init("printd", [], .function, 30)
                )
            ]
        )
    }
    
    func testExtern2() throws {
        let code = "extern printd(x);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.prototype(
                    .init("printd", ["x"], .function, 30)
                )
            ]
        )
    }
    
    func testExtern3() throws {
        let code = "extern printd(x y);"
        let exprs = Parser(input: code).parse()
        
        XCTAssertEqual(
            exprs,
            [
                Expr.prototype(
                    .init("printd", ["x", "y"], .function, 30)
                )
            ]
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
            exprs,
            [
                Expr.function(
                    Self.emptyTopFunction,
                    .if(
                        .binary(.variable("x"), "<", .number(3)),
                        .number(1),
                        .variable("x")
                    )
                )
            ]
        )
    }
    
    func testMultiIf() throws {
        let code = """
        def density(d)
          if d < 8 then
            1 # ' '
          else if d < 4 then
            2 # ' '
          else if d < 2 then
            3 # ' '
          else
            4; # ' '
        """
        
        let exprs = Parser(input: code).parse()
        XCTAssertEqual(
            exprs,
            [
                .function(
                    .init("density", ["d"], .function, 30),
                    .if(
                        .binary(.variable("d"), "<", .number(8)),
                        .number(1),
                        .if(
                            .binary(.variable("d"), "<", .number(4)),
                            .number(2),
                            .if(
                                .binary(.variable("d"), "<", .number(2)),
                                .number(3),
                                .number(4)
                            )
                        )
                    )
                )
            ]
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
            exprs,
            [
            Expr.function(
                Self.emptyTopFunction,
                .binary(
                    .variable("a"),
                    "<",
                    .binary(
                        .binary(.variable("b"), "+", .variable("c")),
                        "-",
                        .binary(.variable("d"), "*", .variable("e"))
                    )
                )
                
            )
                ]
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
            exprs,
            [
            Expr.function(
                Self.emptyTopFunction,
                .binary(
                    .variable("a"),
                    "<",
                    .binary(
                        .binary(.variable("b"), "-", .variable("c")),
                        "+",
                        .binary(.variable("d"), "*", .variable("e"))
                    )
                )
                
            )
                ]
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
            exprs,
            [
                Expr.function(
                    .init("unary!", ["v"], .unary, 30),
                    .number(1)
                )
            ]
        )
    }
    
    func testBinary() {
        let code = """
        def binary| 5 (LHS RHS)
          1;
        """
        
        let exprs = Parser(input: code).parse()
        XCTAssertEqual(
            exprs,
            [
                Expr.function(
                    .init("binary|", ["LHS", "RHS"], .binary, 5),
                    .number(1)
                )
            ]
        )
    }
    
    func testLesson6Example() {
        let code = """
        # Logical unary not.
        def unary!(v)
        if v then
            0
        else
            1;
        
        # Unary negate.
        def unary-(v)
        0-v;
        
        # Define > with the same precedence as <.
        def binary> 10 (LHS RHS)
        RHS < LHS;
        
        # Binary logical or, which does not short circuit.
        def binary| 5 (LHS RHS)
        if LHS then
            1
        else if RHS then
            1
        else
            0;
        
        # Binary logical and, which does not short circuit.
        def binary& 6 (LHS RHS)
        if !LHS then
            0
        else
            !!RHS;
        
        # Define = with slightly lower precedence than relationals.
        def binary = 9 (LHS RHS)
        !(LHS < RHS | LHS > RHS);
        
        # Define ':' for sequencing: as a low-precedence operator that ignores operands
        # and just returns the RHS.
        def binary : 1 (x y) y;
        
        def printdensity(d)
        if d > 8 then
            putchard(32)  # ' '
        else if d > 4 then
            putchard(46)  # '.'
        else if d > 2 then
            putchard(43)  # '+'
        else
            putchard(42); # '*'
        
        # Determine whether the specific location diverges.
        # Solve for z = z^2 + c in the complex plane.
        def mandelconverger(real imag iters creal cimag)
        if iters > 255 | (real*real + imag*imag > 4) then
            iters
        else
            mandelconverger(real*real - imag*imag + creal,
                            2*real*imag + cimag,
                            iters+1, creal, cimag);
        
        # Return the number of iterations required for the iteration to escape
        def mandelconverge(real imag)
        mandelconverger(real, imag, 0, real, imag);
        
        # Compute and plot the mandelbrot set with the specified 2 dimensional range
        # info.
        def mandelhelp(xmin xmax xstep   ymin ymax ystep)
        for y = ymin, y < ymax, ystep in (
            (for x = xmin, x < xmax, xstep in
            printdensity(mandelconverge(x,y)))
            : putchard(10)
        )
        
        # mandel - This is a convenient helper function for plotting the mandelbrot set
        # from the specified position with the specified Magnification.
        def mandel(realstart imagstart realmag imagmag)
        mandelhelp(realstart, realstart+realmag*78, realmag,
                    imagstart, imagstart+imagmag*40, imagmag);
        """
        let exprs = Parser(input: code).parse()
        print(exprs)
    }
    
    func testLesson6() throws {
        let code = """
        # Logical unary not.
        def unary!(v)
          if v then
            0
          else
            1;

        # Unary negate.
        def unary-(v)
          0-v;

        # Define > with the same precedence as <.
        def binary> 10 (LHS RHS)
          RHS < LHS;

        # Binary logical or, which does not short circuit.
        def binary| 5 (LHS RHS)
          if LHS then
            1
          else if RHS then
            1
          else
            0;

        # Binary logical and, which does not short circuit.
        def binary& 6 (LHS RHS)
          if !LHS then
            0
          else
            !!RHS;

        # Define = with slightly lower precedence than relationals.
        def binary = 9 (LHS RHS)
          !(LHS < RHS | LHS > RHS);

        # Define ':' for sequencing: as a low-precedence operator that ignores operands
        # and just returns the RHS.
        def binary : 1 (x y) y;
        """
        let exprs = Parser(input: code).parse()
        XCTAssertEqual(
            exprs,
            [
                .function(
                    .init("unary!", ["v"], .unary, 30),
                    .if(.variable("v"), .number(0), .number(1))
                ),
                .function(
                    .init("unary-", ["v"], .unary, 30),
                    .binary(.number(0), "-", .variable("v"))
                ),
                .function(
                    .init("binary>", ["LHS", "RHS"], .binary, 10),
                    .binary(.variable("RHS"), "<", .variable("LHS"))
                ),
                .function(
                    .init("binary|", ["LHS", "RHS"], .binary, 5),
                    .if(
                        .variable("LHS"),
                        .number(1),
                        .if(
                            .variable("RHS"),
                            .number(1),
                            .number(0)
                        )
                    )
                ),
                .function(
                    .init("binary&", ["LHS", "RHS"], .binary, 6),
                    .if(
                        .unary("!", .variable("LHS")),
                        .number(0),
                        .unary("!", .unary("!", .variable("RHS")))
                    )
                ),
                .function(
                    .init("binary=", ["LHS", "RHS"], .binary, 9),
                    .unary(
                        "!",
                        .binary(
                            .binary(.variable("LHS"), "<", .variable("RHS")),
                            "|",
                            .binary(.variable("LHS"), ">", .variable("RHS"))
                        )
                    )
                ),
                .function(
                    .init("binary:", ["x", "y"], .binary, 1),
                    .variable("y")
                )
            ]
        )
    }
}
