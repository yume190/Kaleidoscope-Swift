////
////  Parser2.swift
////  Parser2
////
////  Created by 林煒峻 on 2019/11/18.
////
//
//import Foundation
//import Token
//import AST
//import Lexer
//
//public class Parser2 {
//    private let lexer: Lexer
//    
//    @inline(__always)
//    public init(lexer: Lexer) {
//        self.lexer = lexer
//    }
//    
//    @inline(__always)
//    public convenience init(input: String) {
//        self.init(lexer: Lexer(input: input))
//    }
//    
//    @inline(__always)
//    public final func parse() -> [Expressionable] {
//        return self.map{$0}
//    }
//}
//
//extension Parser2: Sequence {
//    public __consuming func makeIterator() -> Parser2.Iterator {
//        return Iterator(lexer: self.lexer)
//    }
//}
//
//extension Parser2 {
//    public final class Iterator: IteratorProtocol {
//        private let lexer: Lexer
//        private let iterator : Lexer.Iterator
//        private var currentToken: Token? = nil
//        private let binopPrecedence: [BinaryOperator: Int] = [
//            .less: 10,
//            .plus: 20,
//            .minus: 20,
//            .times: 40
//        ]
//        
//        @inline(__always)
//        public init(lexer: Lexer) {
//            self.lexer = lexer
//            self.iterator = lexer.makeIterator()
//            _ = self.nextToken()
//        }
//        
//        @inline(__always)
//        public convenience init(input: String) {
//            self.init(lexer: Lexer(input: input))
//        }
//        
//        /// top ::= definition | external | expression | ';'
//        public func next() -> Expressionable? {
//            switch self.currentToken {
//            case .none: return nil
//            case .mark(let m) where m == .semicolon :
//                _ = self.nextToken()
//                return self.next()
//            case .keyword(let kw) where kw == .def :
//                return self.parseDefinition()
//            case .keyword(let kw) where kw == .extern :
//                return self.parseExtern()
//            default:
//                return self.parseTopLevelExpr()
//            }
//        }
//    }
//}
//
//extension Parser2.Iterator {
//    private final func nextToken() -> Token? {
//        self.currentToken = iterator.next()
//        return self.currentToken
//    }
//    
//    /// expression
//    ///   ::= primary binoprhs
//    private final func parseExpression() -> Expressionable? {
//        guard let lhs = self.parsePrimary() else {
//            return nil
//        }
//        return self.parseBinOpRHS(exprPrec: 0, lhs: lhs)
//    }
//    
//    private final func getTokenPrecedence() -> Int {
//        guard case let .`operator`(op) = self.currentToken else {
//            return -1
//        }
//        return self.binopPrecedence[op] ?? -1
//    }
//    
//    /// binoprhs
//    ///   ::= ('+' primary)*
//    private final func parseBinOpRHS(exprPrec: Int, lhs: Expressionable) -> Expressionable? {
//        var lhs: Expressionable = lhs
//        while true {
//            let tokenPrec = self.getTokenPrecedence()
//            if tokenPrec < exprPrec {
//                return lhs
//            }
//            
//            // Okay, we know this is a binop.
//            guard case let .operator(binOp) = self.currentToken else {return nil}
//            _ = self.nextToken() // eat binop
//            
//            guard var rhs = self.parsePrimary() else {
//                return nil
//            }
//            
//            // If BinOp binds less tightly with RHS than the operator after RHS, let
//            // the pending operator take RHS as its LHS.
//            let nextPrec = self.getTokenPrecedence()
//            if tokenPrec < nextPrec {
//                guard let nextRhs = self.parseBinOpRHS(exprPrec: tokenPrec + 1, lhs: rhs) else {
//                    return nil
//                }
//                rhs = nextRhs
//            }
//            
//            // Merge LHS/RHS.
//            lhs = BinaryAST(lhs, binOp, rhs)
//        }
//    }
//    
//    /// prototype
//    ///   ::= id '(' id* ')'
//    private final func parsePrototype() -> PrototypeAST? {
//        guard case let .identifier(fnName) = self.currentToken else {
//            print("Expected function name in prototype")
//            return nil
//        }
//        
//        _ = self.nextToken()
//        
//        if currentToken != .mark(.openParen) {
//            print("Expected '(' in prototype")
//            return nil
//        }
//        
//        var argNames: [String] = []
//        while case let .identifier(id) = self.nextToken() {
//            argNames.append(id)
//        }
//        
//        if currentToken != .mark(.closeParen) {
//            print("Expected ')' in prototype")
//            return nil
//        }
//        
//        _ = self.nextToken() // eat ')'
//        
//        return PrototypeAST(fnName, argNames)
//    }
//    
//    /// definition ::= 'def' prototype expression
//    private final func parseDefinition() -> Expressionable? {
//        _ = self.nextToken() // eat def.
//        
//        guard let prototype = self.parsePrototype() else {
//            return nil
//        }
//        
//        guard let e = self.parseExpression() else {
//            return nil
//        }
//        return FunctionAST(prototype, e)
//    }
//    
//    /// external ::= 'extern' prototype
//    private final func parseExtern() -> Expressionable? {
//        _ = self.nextToken()
//        return self.parsePrototype()
//    }
//    
//    /// toplevelexpr ::= expression
//    private final func parseTopLevelExpr() -> Expressionable? {
//        guard let e = self.parseExpression() else {
//            return nil
//        }
//        
//        return FunctionAST(.init(""), e)
//    }
//    
//    /// primary
//    ///   ::= identifierexpr
//    ///   ::= numberexpr
//    ///   ::= parenexpr
//    private final func parsePrimary() -> Expressionable? {
//        switch self.currentToken {
//        case .number:
//            return self.parseNumberExpr()
//        case .comment:
//            return self.next()
//        case .identifier:
//            return self.parseIdentifierExpr()
//        case .mark(let mark) where mark == .openParen:
//            return self.parseParenExpr()
//        /// L5
//        case .keyword(let kw) where kw == .if:
//            return self.parseIfExpr()
//        default:
//            print("unknown token when expecting an expression")
//            return nil
//        }
//    }
//    
//    /// numberexpr ::= number
//    private final func parseNumberExpr() -> Expressionable? {
//        guard case let .number(num) = self.currentToken else {
//            return nil
//        }
//        _ = self.nextToken()
//        return NumberAST(num)
//    }
//    
//    /// parenexpr ::= '(' expression ')'
//    private final func parseParenExpr() -> Expressionable? {
//        _ = self.nextToken() // (
//        
//        guard let expr = self.parseExpression() else {
//            return nil
//        }
//        
//        if currentToken != .mark(.closeParen) {
//            print("expected ')'")
//            return nil
//        }
//        
//        _ = self.nextToken() // )
//        return expr
//    }
//    
//    /// identifierexpr
//    ///   ::= identifier
//    ///   ::= identifier '(' expression* ')'
//    private final func parseIdentifierExpr() -> Expressionable? {
//        guard case let .identifier(id) = self.currentToken else {
//            return nil
//        }
//        
//        
//        _ = self.nextToken() /// eat identifier.
//        guard self.currentToken == .mark(.openParen) else {
//            return VariableAST(id)
//        }
//        
//        _ = self.nextToken() /// eat '('
//        guard self.currentToken != .mark(.closeParen) else {
//            defer {
//                _ = self.nextToken() /// eat ')'
//            }
//            return CallAST(id)
//        }
//        
//        var exprs: [Expressionable] = []
//        
//        while true {
//            if let expr = self.parseExpression() {
//                exprs.append(expr)
//            } else {
//                return nil
//            }
//            
//            if self.currentToken == .mark(.closeParen) {
//                break
//            }
//            
//            if self.currentToken != .mark(.comma) {
//                print("Expected ')' or ',' in argument list")
//                return nil
//            }
//            
//            _ = self.nextToken()
//        }
//        _ = self.nextToken() /// eat ')'
//        
//        return CallAST(id, exprs)
//    }
//    
//    /// L5
//    /// ifexpr ::= 'if' expression 'then' expression 'else' expression
//    private final func parseIfExpr() -> Expressionable? {
//        _ = self.nextToken() // eat if
//        
//        guard let cond = self.parseExpression() else {return nil}
//        
//        if currentToken != .keyword(.then) {
//            print("expected then")
//            return nil
//        }
//        
//        _ = self.nextToken() // eat then
//        
//        guard let then = self.parseExpression() else { return nil }
//        
//        if currentToken != .keyword(.else) {
//            print("expected else")
//            return nil
//        }
//        
//        _ = self.nextToken()
//        
//        guard let `else` = self.parseExpression() else { return nil }
//        
//        return IfAST(cond, then, `else`)
//    }
//}
//
////===----------------------------------------------------------------------===//
//// Top-Level parsing
////===----------------------------------------------------------------------===//
//
////extension Parser2.Iterator {
////    func handleDefinition() {
////        if let _ = self.parseDefinition() {
////            print("Parsed a function definition.\n")
////        } else {
////            _ = self.nextToken()
////        }
////    }
////
////    func handleExtern() {
////        if let _ = self.parseExtern() {
////            print("Parsed an extern\n")
////        } else {
////            _ = self.nextToken()
////        }
////    }
////
////    func handleTopLevelExpression() {
////        if let _ = self.parseTopLevelExpr() {
////            print("Parsed a top-level expr\n")
////        } else {
////            _ = self.nextToken()
////        }
////    }
////}