//
//  AST3.swift
//  AST
//
//  Created by 林煒峻 on 2019/11/18.
//

import Foundation
import Token

public indirect enum Expr: Equatable {
    case number(Double)
    case variable(String)
    /// lhs op rhs
    case binary(Expr, BinaryOperator, Expr)
    
    /// L5 AST Extensions for If/Then/Else
    /// std::unique_ptr<ExprAST> Cond, Then, Else;
    /// Cond, Then, Else;
    case `if`(Expr, Expr, Expr)
    case call(String, [Expr])
    /// name params
    case prototype(String, [String])
    /// name params expr
    case function(String, [String], Expr)
    /// name start end step body
    case `for`(String, Expr, Expr, Expr?, Expr)
}

extension Expr: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .number(num):
            return "\(num)"
        case let .variable(`var`):
            return "\(`var`)"
        case let .binary(lhs, op, rhs):
            return """
            (\(lhs) \(op) \(rhs))
            """
            
        case let .if(cond, then, `else`):
            return """
            if \(cond) then
                \(then)
            else
                \(`else`);
            """
        case let .call(name, exprs):
            return "\(name)(\(exprs.map{$0.description}.joined(separator: " ")))"
        case let .prototype(name, args):
            return "extern \(name)(\(args.map{$0.description}.joined(separator: " ")))"
        case let .function(name, args, expr):
            return """
            func \(name)(\(args.map{$0.description}.joined(separator: " "))) {
            \(expr)
            }
            """
        case let .for(name, start, end, step, body):
            let _step = step.map {", \($0)"} ?? ""
            return """
            for \(name) = \(start) , \(end)\(_step) in
                \(body)
            """
        }
    }
}
