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
    
    private var contexts = Contexts()
    
    class override func setUp() {
        super.setUp()
        /// https://juejin.im/post/5dc3805df265da4d1518efb4
        /// ignore SIGPIPE
        signal(SIGPIPE, SIG_IGN)
    }
    
    override func setUp() {
        super.setUp()
        self.contexts = Contexts(isActiveOptimizerPass: false)
    }
    
    func testTopCommand() {
        let code = "4+5"

        let exprs = Parser(input: code).parse()
        XCTAssertEqual(exprs.count, 1)
        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
        XCTAssertEqual(ir, """

        define double @0() {
        entry:
          ret double 9.000000e+00
        }

        """)
    }
    
//    func testFunction() {
//        let code = "def foo(a b) a*a + 2*a*b + b*b;"
//
//        let exprs = Parser(input: code).parse()
//        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
//        XCTAssertEqual(exprs.count, 1)
//        XCTAssertEqual(ir, """
//
//        define double @foo(double %a, double %b) {
//        entry:
//          %multmp = fmul double %a, %a
//          %multmp1 = fmul double 2.000000e+00, %a
//          %multmp2 = fmul double %multmp1, %b
//          %addtmp = fadd double %multmp, %multmp2
//          %multmp3 = fmul double %b, %b
//          %addtmp4 = fadd double %addtmp, %multmp3
//          ret double %addtmp4
//        }
//
//        """)
//    }
    
    /// Problem: (x + 3) * 2
    /// Answer: tmp = x + 3, result = tmp*tmp;
    /// tips:
    ///   * reassociation of expressions(to make the add’s lexically identical)
    ///    * Common Subexpression Elimination (CSE)
//    func testOptimizePassNone() {
//        let code = "def test(x) (1+2+x)*(x+(1+2));"
//
//        let exprs = Parser(input: code).parse()
//        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
//        XCTAssertEqual(ir, """
//
//        define double @test(double %x) {
//        entry:
//          %addtmp = fadd double 3.000000e+00, %x
//          %addtmp1 = fadd double %x, 3.000000e+00
//          %multmp = fmul double %addtmp, %addtmp1
//          ret double %multmp
//        }
//
//        """)
//    }
    
    func testOptimizePassHave() {
        self.contexts = Contexts()
        
        let code = "def test(x) (1+2+x)*(x+(1+2));"
        
        let exprs = Parser(input: code).parse()
        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
        XCTAssertEqual(ir, """

        define double @test(double %x) {
        entry:
          %addtmp = fadd double %x, 3.000000e+00
          %multmp = fmul double %addtmp, %addtmp
          ret double %multmp
        }

        """)
    }
    
//    func testIf() {
//        let code = """
//        extern foo();
//        extern bar();
//        def baz(x) if x then foo() else bar();
//        """
//
//        let exprs = Parser(input: code).parse()
//        XCTAssertEqual(exprs.count, 3)
//        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
//        print(ir)
//        XCTAssertEqual(ir, """
//
//        declare double @foo()
//
//        declare double @bar()
//
//        define double @baz(double %x) {
//        entry:
//          %ifcond = fcmp one double %x, 0.000000e+00
//          br i1 %ifcond, label %then, label %else
//
//        then:                                             ; preds = %entry
//          %calltmp = call double @foo()
//          br label %ifcont
//
//        else:                                             ; preds = %entry
//          %calltmp1 = call double @bar()
//          br label %ifcont
//
//        ifcont:                                           ; preds = %else, %then
//          %iftmp = phi double [ %calltmp, %then ], [ %calltmp1, %else ]
//          ret double %iftmp
//        }
//
//        """)
//    }
    
//    func testFor() {
//        let code = """
//        extern putchard(char);
//        def printstar(n)
//            for i = 1, i < n, 1.0 in
//                putchard(42);  # ascii 42 = '*'
//
//        # print 100 '*' characters
//        printstar(100);
//        """
//        
//        let exprs = Parser(input: code).parse()
//        XCTAssertEqual(exprs.count, 3)
//        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
//        print(ir)
//        
//        XCTAssertEqual(ir, """
//
//        declare double @putchard(double %char)
//
//        define double @printstar(double %n) {
//        entry:
//          br label %loop
//
//        loop:                                             ; preds = %loop, %entry
//          %i = phi double [ 1.000000e+00, %entry ], [ %nextvar, %loop ]
//          %calltmp = call double @putchard(double 4.200000e+01)
//          %nextvar = fadd double %i, 1.000000e+00
//          %cmptmp = fcmp ult double %i, %n
//          %booltmp = uitofp i1 %cmptmp to double
//          %loopcond = fcmp one double %booltmp, 0.000000e+00
//          br i1 %loopcond, label %loop, label %afterloop
//
//        afterloop:                                        ; preds = %loop
//          ret double 0.000000e+00
//        }
//
//        define double @0() {
//        entry:
//          %calltmp = call double @printstar(double 1.000000e+02)
//          ret double %calltmp
//        }
//
//        """)
//    }
    
    func testLesson7() {
        let code = """
        def a()
            var a = 1 in a;
        """
        
        let exprs = Parser(input: code).parse()
        let ir = exprs.compactMap {$0.codeGen(self.contexts)?.pipe()}.joined(separator: "")
        print(ir)
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


