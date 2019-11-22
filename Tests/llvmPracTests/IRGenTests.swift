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

final class IRGenTests: XCTestCase {
    //ready> 4+5;
    //Read top-level expression:
    //define double @0() {
    //entry:
    //  ret double 9.000000e+00
    //}

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


