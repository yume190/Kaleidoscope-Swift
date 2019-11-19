//
//  AST3.swift
//  AST
//
//  Created by 林煒峻 on 2019/11/18.
//

import Foundation
import Token

public struct Prototype {
    let name: String
    let params: [String]
}

public typealias Definition = Function
public struct Function {
    let prototype: Prototype
    let expr: Expr
}

public indirect enum Expr: Equatable {
    /// numberexpr ::= number
    case number(Double)
    case variable(String)
    case binary(Expr, BinaryOperator, Expr)
    // github 多得
    // case ifelse(Expr, Expr, Expr)
    case call(String, [Expr])
    case prototype(String, [String])
    case function(String, [String], Expr)
}
