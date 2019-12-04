//
//  IRGenTests.swift
//  AST
//
//  Created by 林煒峻 on 2019/11/22.
//

import XCTest
import class Foundation.Bundle
@testable import Lexer
@testable import AST
@testable import Token
@testable import Parser
@testable import IRGen

final class IRGenTests: XCTestCase {
    
    class override func setUp() {
        super.setUp()
        /// https://juejin.im/post/5dc3805df265da4d1518efb4
        /// ignore SIGPIPE
        signal(SIGPIPE, SIG_IGN)
    }
    
    func testTopCommand() {
        let code = "4+5"

        let tokens = Parser(input: code).parse()
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].codeGen()?.pipe(), """

        define double @0() {
        entry:
          ret double 9.000000e+00
        }

        """)
    }
    
    func testFunction() {
        let code = "def foo(a b) a*a + 2*a*b + b*b;"

        let tokens = Parser(input: code).parse()
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].codeGen()?.pipe(), """

        define double @foo(double %a, double %b) {
        entry:
          %multmp = fmul double %a, %a
          %multmp1 = fmul double 2.000000e+00, %a
          %multmp2 = fmul double %multmp1, %b
          %addtmp = fadd double %multmp, %multmp2
          %multmp3 = fmul double %b, %b
          %addtmp4 = fadd double %addtmp, %multmp3
          ret double %addtmp4
        }

        """)
    }
    
    func testOptimizePass() {
        let code1 = "def test(x) (1+2+x)*(x+(1+2));"

        let tokens1 = Parser(input: code1).parse()
        XCTAssertEqual(tokens1.count, 1)
        XCTAssertEqual(tokens1[0].codeGen()?.pipe(), """

        define double @test(double %x) {
        entry:
          %addtmp = fadd double 3.000000e+00, %x
          %addtmp1 = fadd double %x, 3.000000e+00
          %multmp = fmul double %addtmp, %addtmp1
          ret double %multmp
        }

        """)
        
        let code2 = "def test2(x) (1+2+x)*(x+(1+2));"

        Gen.main.activeOptimizerPass()
        let tokens2 = Parser(input: code2).parse()
        XCTAssertEqual(tokens2.count, 1)
        XCTAssertEqual(tokens2[0].codeGen()?.pipe(), """

        define double @test2(double %x) {
        entry:
          %addtmp = fadd double %x, 3.000000e+00
          %multmp = fmul double %addtmp, %addtmp
          ret double %multmp
        }

        """)
    }
    
//    func testABC() {
//        dump(code: "def foo(a b) a*a + 2*a*b + b*b;")
//
//        /// Problem: (x + 3) * 2
//        /// Answer: tmp = x + 3, result = tmp*tmp;
//        /// tips:
//        ///   * reassociation of expressions(to make the add’s lexically identical)
//        //    * Common Subexpression Elimination (CSE)
//        dump(code: "def test(x) (1+2+x)*(x+(1+2));")
//        // define double @test(double %x) {
//        // entry:
//        //         %addtmp = fadd double 3.000000e+00, %x
//        //         %addtmp1 = fadd double %x, 3.000000e+00
//        //         %multmp = fmul double %addtmp, %addtmp1
//        //         ret double %multmp
//        // }
//
//        Gen.main.activeOptimizerPass()
//        dump(code: "def test2(x) (1+2+x)*(x+(1+2));")
//        // define double @test(double %x) {
//        // entry:
//        //         %addtmp = fadd double %x, 3.000000e+00
//        //         %multmp = fmul double %addtmp, %addtmp
//        //         ret double %multmp
//        // }
//
//
//
//        RunLoop.main.run()
//
//    }

//    static var allTests = [
//        ("testFullCode1", testFullCode1),
//        ("testComment", testComment)
//    ]
}


