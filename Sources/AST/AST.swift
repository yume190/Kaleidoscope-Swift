//
//  AST3.swift
//  AST
//
//  Created by 林煒峻 on 2019/11/18.
//

import Foundation
import Token


public struct Prototype: Equatable {
    public enum Kind: Equatable {
        case function
        case unary
        case binary
    }
    
    public let name: String
    public let arguments: [String]
    public let kind: Kind
    public let precedence: Precedence
    
    public init(
        _ name: String,
        _ arguments: [String],
        _ kind: Kind,
        _ precedence: Precedence
    ) {
        self.name = name
        self.arguments = arguments
        self.kind = kind
        self.precedence = precedence
    }
}
public struct Pair<A: Equatable, B: Equatable>: Equatable {
    public let first: A
    public let second: B
    
    public init(_ first: A, _ second: B) {
        self.first = first
        self.second = second
    }
}
public indirect enum Expr: Equatable {
    case number(Double)
    case variable(String)
    /// lhs op rhs
    case binary(Expr, Character, Expr)
    
    /// L5 AST Extensions for If/Then/Else
    /// std::unique_ptr<ExprAST> Cond, Then, Else;
    /// Cond, Then, Else;
    case `if`(Expr, Expr, Expr)
    case call(_ name: String, _ exprs: [Expr])

    /// name params
    case prototype(_ proto: Prototype)
        
    /// name params expr
    case function(_ proto: Prototype, _ expr: Expr)
    /// name start end step body
    case `for`(_ name: String, _ start: Expr, _ end: Expr, _ step: Expr?, _ body: Expr)
    
    /// op, operand
    case unary(_ op: Character, _ operand: Expr)
    
    // lesson 7 variable
    /// name
    case `var`(_ names: [Pair<String, Expr>], _ body: Expr)
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
        case let .prototype(proto):
            #warning("TODO")
            switch proto.kind {
            case .function:
                return "extern \(proto.name)(\(proto.arguments.map{$0.description}.joined(separator: " ")))"
            default: break
            }
            return "extern \(proto.name)(\(proto.arguments.map{$0.description}.joined(separator: " ")))"
        case let .function(proto, expr):
            
            switch proto.kind {
            case .function:
                return """
                def \(proto.name)(\(proto.arguments.map{$0.description}.joined(separator: " "))) {
                \(expr)
                }
                """
            case .unary:
                return """
                def \(proto.name)(\(proto.arguments.map{$0.description}.joined(separator: " "))) {
                \(expr)
                }
                """
            case .binary:
                return """
                def \(proto.name) \(proto.precedence) (\(proto.arguments.map{$0.description}.joined(separator: " "))) {
                \(expr)
                }
                """
            }    
        case let .for(name, start, end, step, body):
            let _step = step.map {", \($0)"} ?? ""
            return """
            for \(name) = \(start) , \(end)\(_step) in
                \(body)
            """
        case let .unary(op, expr):
            return """
            \(op)\(expr)
            """
        default:
            return ""
        }
    }
}
