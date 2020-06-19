////
////  File.swift
////  
////
////  Created by Yume on 2020/6/19.
////
//
//import Foundation
//import Token
//
//public protocol Expressionable: CustomStringConvertible, Equatable {
//    
//}
//
//public struct NumberAST: Expressionable {
//    public let value: Double
//    public init(_ number: Double) {
//        self.value = number
//    }
//    public var description: String {
//        "\(value)"
//    }
//}
//
//public struct VariableAST: Expressionable {
//    public let name: String
//    public init(_ variable: String) {
//        self.name = variable
//    }
//    public var description: String {
//        name
//    }
//}
//
//public struct BinaryAST: Expressionable {
//    public let lhs: Expressionable
//    public let op: BinaryOperator
//    public let rhs: Expressionable
//    public init(_ lhs: Expressionable, _ op: BinaryOperator, _ rhs: Expressionable) {
//        self.lhs = lhs
//        self.op = op
//        self.rhs = rhs
//    }
//    public var description: String {
//        "(\(lhs) \(op) \(rhs))"
//    }
//}
//
//public struct IfAST: Expressionable {
//    public let cond: Expressionable
//    public let then: Expressionable
//    public let `else`: Expressionable
//    public init(_ cond: Expressionable, _ then: Expressionable, _ `else`: Expressionable) {
//        self.cond = cond
//        self.then = then
//        self.`else` = `else`
//    }
//    public var description: String {
//        """
//        if \(cond) then
//        \(then)
//        else
//        \(`else`);
//        """
//    }
//}
//
//public struct CallAST: Expressionable {
//    public let callee: String
//    public let args: [Expressionable]
//    public init(_ name: String, _ exprs: [Expressionable] = []) {
//        self.callee = name
//        self.args = exprs
//    }
//    public var description: String {
//        "\(callee)(\(args.map{$0.description}.joined(separator: " ")))"
//    }
//}
//
//public struct PrototypeAST: Expressionable {
//    public let name: String
//    public let args: [String]
//    public init(_ name: String, _ args: [String] = []) {
//        self.name = name
//        self.args = args
//    }
//    public var description: String {
//        "extern \(name)(\(args.map{$0.description}.joined(separator: " ")))"
//    }
//}
//
//public struct FunctionAST: Expressionable {
//    public let prototype: PrototypeAST
//    public let expr: Expressionable
//    public init(_ prototype: PrototypeAST, _ expr: Expressionable) {
//        self.prototype = prototype
//        self.expr = expr
//    }
//    public var description: String {
//        """
//        func \(prototype.name)(\(prototype.args.map{$0.description}.joined(separator: " "))) {
//            \(expr)
//        }
//        """
//    }
//}
