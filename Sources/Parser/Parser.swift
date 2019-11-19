//
//  Parser.swift
//  Parser
//
//  Created by 林煒峻 on 2019/11/18.
//

import Foundation
import Token
import AST
import Lexer

public class Parser {
    private let lexer: Lexer
    
    @inline(__always)
    public init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    @inline(__always)
    public convenience init(input: String) {
        self.init(lexer: Lexer(input: input))
    }
    
    @inline(__always)
    public final func parse() -> [Expr] {
        return self.map{$0}
    }
}

extension Parser: Sequence {
    public __consuming func makeIterator() -> Parser.Iterator {
        return Iterator(lexer: self.lexer)
    }
}

extension Parser {
    public final class Iterator: IteratorProtocol {
        private let lexer: Lexer
        private let iterator : Lexer.Iterator
        private var currentToken: Token? = nil
        private let binopPrecedence: [BinaryOperator: Int] = [
            .less: 10,
            .plus: 20,
            .minus: 20,
            .times: 40
        ]
        
        @inline(__always)
        public init(lexer: Lexer) {
            self.lexer = lexer
            self.iterator = lexer.makeIterator()
        }
        
        @inline(__always)
        public convenience init(input: String) {
            self.init(lexer: Lexer(input: input))
        }
        
        /// primary
        ///   ::= identifierexpr
        ///   ::= numberexpr
        ///   ::= parenexpr
        public func next() -> Expr? {
            switch self.nextToken() {
            case .number:
                return self.parseNumberExpr()
            case .comment:
                return self.next()
            case .identifier:
                return self.parseIdentifierExpr()
            case .mark(let mark) where mark == .openParen:
                return self.parseParenExpr()
    //        case .keyword:
    //            return nil
    //        case .mark:
    //            return nil
    //        case .operator:
    //            return nil
            default:
                print("unknown token when expecting an expression")
                return nil
            }
        }
    }
}
 
extension Parser.Iterator {
    func nextToken() -> Token? {
        self.currentToken = iterator.next()
        return self.currentToken
    }
    
    /// expression
    ///   ::= primary binoprhs
    private func ParseExpression() -> Expr? {
        guard let lhs = self.parsePrimary() else {
            return nil
        }
        return self.parseBinOpRHS(exprPrec: 0, lhs: lhs)
    }
    
    private func getTokenPrecedence() -> Int {
        guard case let .`operator`(op) = self.currentToken else {
            return -1
        }
        return self.binopPrecedence[op] ?? -1
    }
    
    /// binoprhs
    ///   ::= ('+' primary)*
    func parseBinOpRHS(exprPrec: Int, lhs: Expr) -> Expr? {
        var lhs: Expr = lhs
        while true {
            let tokenPrec = self.getTokenPrecedence()
            if tokenPrec < exprPrec {
                return lhs
            }
            
            // Okay, we know this is a binop.
            guard case let .operator(binOp) = self.currentToken else {return nil}
            _ = self.nextToken() // eat binop


            guard var rhs = self.parsePrimary() else {
                return nil
            }
            
            // If BinOp binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrec = self.getTokenPrecedence()
            if tokenPrec < nextPrec {
                guard let nextRhs = self.parseBinOpRHS(exprPrec: tokenPrec + 1, lhs: rhs) else {
                    return nil
                }
                rhs = nextRhs
            }
            
            // Merge LHS/RHS.
            lhs = .binary(lhs, binOp, rhs)
        }
    }
    
    /// prototype
    ///   ::= id '(' id* ')'
    func parsePrototype() -> Expr? {
        guard case let .identifier(fnName) = self.currentToken else {
            print("Expected function name in prototype")
            return nil
        }
        
        _ = self.nextToken()
        
        if currentToken != .mark(.openParen) {
            print("Expected '(' in prototype")
            return nil
        }
        
        var argNames: [String] = []
        while case let .identifier(id) = self.nextToken() {
            argNames.append(id)
        }
        
        if currentToken != .mark(.closeParen) {
            print("Expected ')' in prototype")
            return nil
        }
        
        _ = self.nextToken() // eat ')'
        
        return .prototype(fnName, argNames)
    }
    
    /// primary
    ///   ::= identifierexpr
    ///   ::= numberexpr
    ///   ::= parenexpr
    private func parsePrimary() -> Expr? {
        switch self.nextToken() {
        case .number:
            return self.parseNumberExpr()
        case .comment:
            return self.next()
        case .identifier:
            return self.parseIdentifierExpr()
        case .mark(let mark) where mark == .openParen:
            return self.parseParenExpr()
        default:
            print("unknown token when expecting an expression")
            return nil
        }
    }
    
    
    
    /// numberexpr ::= number
    private func parseNumberExpr() -> Expr? {
        guard case let .number(num) = self.currentToken else {
            return nil
        }
        return .number(num)
    }
    
    /// parenexpr ::= '(' expression ')'
    private func parseParenExpr() -> Expr? {
        // (
        // V = Expr
        // )
        return nil
    }
    
    /// identifierexpr
    ///   ::= identifier
    ///   ::= identifier '(' expression* ')'
    private func parseIdentifierExpr() -> Expr? {
        guard case let .identifier(id) = self.currentToken else {
            return nil
        }
        
        /// eat identifier.
        _ = self.nextToken()
        guard self.currentToken == .mark(.openParen) else {
            return .variable(id)
        }
        
        _ = self.nextToken()
        guard self.currentToken != .mark(.closeParen) else {
            return .call(id, [])
        }
        
        var exprs: [Expr] = []
        
        while true {
            if let expr = self.parseExpression() {
                exprs.append(expr)
            } else {
                return nil
            }
            
            if self.currentToken == .mark(.closeParen) {
                break
            }
            
            if self.currentToken != .mark(.comma) {
                #warning("log error")
                // error
                return nil
            }
            
            _ = self.nextToken()
        }
        return .call(id, exprs)
    }
    
    private func parseExpression() -> Expr? {
        return nil
    }
    
    
}
