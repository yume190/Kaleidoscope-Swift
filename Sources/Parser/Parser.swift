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
import Tool

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
        private var binopPrecedence: [Character: Precedence] = [
            BinaryOperator.less.rawValue: 10,
            BinaryOperator.plus.rawValue: 20,
            BinaryOperator.minus.rawValue: 20,
            BinaryOperator.times.rawValue: 40,
            BinaryOperator.equals.rawValue: 2
            
        ]
        
        @inline(__always)
        public init(lexer: Lexer) {
            self.lexer = lexer
            self.iterator = lexer.makeIterator()
            _ = self.nextToken()
        }
        
        @inline(__always)
        public convenience init(input: String) {
            self.init(lexer: Lexer(input: input))
        }

        /// top ::= definition | external | expression | ';'
        public func next() -> Expr? {
            switch self.currentToken {
            case .none: return nil
            case .keyword(.def):
                return self.parseDefinition()
            case .keyword(.extern):
                return self.parseExtern()
            default:
                return self.parseTopLevelExpr()
            }
        }
    }
}
 
extension Parser.Iterator {
    @discardableResult
    private final func nextToken() -> Token? {
        while let token = iterator.next() {
            if case .comment = token {
                continue
            } else if case .mark(.semicolon) = token {
                continue
            } else {
                self.currentToken = token
                return self.currentToken
            }
        }
        self.currentToken = nil
        return self.currentToken
    }
    
    /// expression
    ///   ::= primary binoprhs
    private final func parseExpression() -> Expr? {
        guard let lhs = self.parseUnary() else {
            return nil
        }
        return self.parseBinOpRHS(exprPrec: 0, lhs: lhs)
    }
    
    private final func getTokenPrecedence() -> Int {
        switch self.currentToken {
        case let .operator(op): 
            return self.binopPrecedence[op.rawValue] ?? -1
        case let .other(op):
            return self.binopPrecedence[op] ?? -1
        default:
            return -1
        }
    }
    
    /// unary
    ///   ::= primary
    ///   ::= '!' unary
    private final func parseUnary() -> Expr? {
        guard let token = currentToken else {return nil}
        
        if !token.isASCII {
            return self.parsePrimary()
        }
        switch token {
        case .mark(.openParen), .mark(.comma):
            return self.parsePrimary()
        default:
            break
        }
        
        switch currentToken {
        case .other(let char):
            _ = self.nextToken()
            guard let expr = self.parseUnary() else { printE("should parse unary");return nil }
            return .unary(char, expr)
        default:
            return nil
        }
    }
    
    /// binoprhs
    ///   ::= ('+' primary)*
    ///   ::= ('+' unary)*
    private final func parseBinOpRHS(exprPrec: Int, lhs: Expr) -> Expr? {
        var lhs: Expr = lhs
        while true {
            let tokenPrec = self.getTokenPrecedence()
            if tokenPrec < exprPrec {
                return lhs
            }
            
            // Okay, we know this is a binop.
            guard let binOp = self.currentToken?.char else {return nil}
            _ = self.nextToken() // eat binop

            guard var rhs = self.parseUnary() else {
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
    ///   Lesson 6
    ///   ::= binary LETTER number? (id, id)
    ///   ::= unary LETTER (id)
    private final func parsePrototype() -> Expr? {
        enum Prototype {
            case proto(_ id: String)
            case unary(_ id: String) // pred 30
            case binary(_ id: String, _ pred: Precedence)
        }

        let prototype: Prototype
        
        switch self.currentToken {
        case let .identifier(fnName):
            prototype = .proto(fnName)
            _ = nextToken()
            
        case .keyword(.unary):
            _ = nextToken()
            guard let char = currentToken!.char else { printE("Expected binary operator");return nil}
            guard currentToken!.isASCII else { printE("Expected unary operator");return nil}
            var id = "unary"
            id.append(char)
            prototype = .unary(id)
            _ = nextToken()
        case .keyword(.binary):
            _ = nextToken()
            guard let char = currentToken!.char else { printE("Expected binary operator");return nil}
            guard currentToken!.isASCII else { printE("Expected unary operator");return nil}
            var id = "binary"
            id.append(char)
            _ = nextToken() // eat op
            
            if case let .number(num) = self.currentToken {
                guard 1 <= num && num <= 100 else {
                    printE("Invalid precedence: must be 1..100")
                    return nil
                }
                prototype = .binary(id, Precedence(num))
                _ = nextToken() // eat Precedence
                break
            }
            prototype = .binary(id, 30)
        default:
            printE("Expected function name in prototype")
            return nil
        }
        
        if currentToken != .mark(.openParen) {
            printE("Expected '(' in prototype")
            return nil
        }
        
        var argNames: [String] = []
        while case let .identifier(id) = self.nextToken() {
            argNames.append(id)
        }
        
        if currentToken != .mark(.closeParen) {
            printE("Expected ')' in prototype")
            return nil
        }
        
        _ = self.nextToken() // eat ')'
        
        switch prototype {
        case .proto(let fnName):
            return .prototype(.init(fnName, argNames, .function, 30))
        case .unary(let op):
            guard argNames.count == 1 else {
                printE("Invalid number of operands for operator")
                return nil
            }
            return .prototype(.init(op, argNames, .unary, 30))
        case let .binary(op, pred):
            guard argNames.count == 2 else {
                printE("Invalid number of operands for operator")
                return nil
            }
            return .prototype(.init(op, argNames, .binary, pred))
        }
    }
    
    /// definition ::= 'def' prototype expression
    private final func parseDefinition() -> Expr? {
        _ = self.nextToken() // eat def.
        
        guard case let .prototype(proto) = self.parsePrototype() else {
            return nil
        }
        
        guard let e = self.parseExpression() else {
            return nil
        }
        if proto.kind == .binary || proto.kind == .unary {
            guard let op: Character = proto.name.last else { printE("should have op");return nil }
            self.binopPrecedence[op] = proto.precedence
        }
        
        return .function(proto, e)
    }
    
    /// external ::= 'extern' prototype
    private final func parseExtern() -> Expr? {
        _ = self.nextToken()
        return self.parsePrototype()
    }
    
    /// toplevelexpr ::= expression
    private final func parseTopLevelExpr() -> Expr? {
        guard let e = self.parseExpression() else {
            return nil
        }
        
        return .function(.init("", [], .function, 30), e)
    }
    
    /// primary
    ///   ::= identifierexpr
    ///   ::= numberexpr
    ///   ::= parenexpr
    private final func parsePrimary() -> Expr? {
        switch self.currentToken {
        case .number:
            return self.parseNumberExpr()
        case .comment:
            _ = nextToken() // eat comment
            return self.parseExpression()
//            return self.next()
        case .identifier:
            return self.parseIdentifierExpr()
        case .mark(let mark) where mark == .openParen:
            return self.parseParenExpr()
        /// L5
        case .keyword(let kw) where kw == .if:
            return self.parseIfExpr()
        /// L5
        case .keyword(let kw) where kw == .for:
            return self.parseForExpr()
        default:
            printE("unknown token when expecting an expression")
            return nil
        }
    }
    
    /// numberexpr ::= number
    private final func parseNumberExpr() -> Expr? {
        guard case let .number(num) = self.currentToken else {
            return nil
        }
        _ = self.nextToken()
        return .number(num)
    }
    
    /// parenexpr ::= '(' expression ')'
    private final func parseParenExpr() -> Expr? {
        _ = self.nextToken() // (
        
        guard let expr = self.parseExpression() else {
            return nil
        }
        
        if currentToken != .mark(.closeParen) {
            printE("expected ')'")
            return nil
        }
        
        _ = self.nextToken() // )
        return expr
    }
    
    /// identifierexpr
    ///   ::= identifier
    ///   ::= identifier '(' expression* ')'
    private final func parseIdentifierExpr() -> Expr? {
        guard case let .identifier(id) = self.currentToken else {
            return nil
        }
        
        
        _ = self.nextToken() /// eat identifier.
        guard self.currentToken == .mark(.openParen) else {
            return .variable(id)
        }
        
        _ = self.nextToken() /// eat '('
        guard self.currentToken != .mark(.closeParen) else {
            defer {
                _ = self.nextToken() /// eat ')'
            }
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
                printE("Expected ')' or ',' in argument list")
                return nil
            }
        
            _ = self.nextToken() 
        }
        _ = self.nextToken() /// eat ')'
        
        return .call(id, exprs)
    }
    
    /// L5
    /// ifexpr ::= 'if' expression 'then' expression 'else' expression
    private final func parseIfExpr() -> Expr? {
        _ = self.nextToken() // eat if
        
        guard let cond = self.parseExpression() else {return nil}
        
        if currentToken != .keyword(.then) {
            printE("expected then")
            return nil
        }
        
        _ = self.nextToken() // eat then

        guard let then = self.parseExpression() else { return nil }
        
        if currentToken != .keyword(.else) {
            printE("expected else")
            return nil
        }

        _ = self.nextToken()

        guard let `else` = self.parseExpression() else { return nil }
        
        return .if(cond, then, `else`)
    }
    
    private final func parseForExpr() -> Expr? {
        _ = self.nextToken() // eat for
        
        guard case let .identifier(name) = currentToken else {
            printE("expected identifier after for")
            return nil
        }
        _ = self.nextToken() // eat identifier
        
        guard currentToken == Token.operator(.equals) else {
            printE("expected '=' after for")
            return nil
        }
        _ = self.nextToken() // eat =
        
        guard let start = self.parseExpression() else {return nil}
        guard currentToken == Token.mark(.comma) else {
            printE("expected ',' after for start value")
            return nil
        }
        _ = self.nextToken() // eat expr
        
        guard let end = self.parseExpression() else {return nil}
        
        var step: Expr?
        if currentToken == Token.mark(.comma) {
            _ = self.nextToken() // eat
            step = parseExpression()
            if step == nil {return nil}
        }
        
        guard Token.keyword(Keyword.in) == currentToken else {
            printE("expected 'in' after for")
            return nil
        }
        _ = self.nextToken() // eat in
        
        guard let body = self.parseExpression() else {return nil}
        
        return .for(name, start, end, step, body)
    }
    
    private final func parseVarExpr() -> Expr? {
        nextToken() // eat var
        
        var varNames: [Pair<String, Expr>] = []
        
        guard case .identifier = currentToken else {
            printE("expected identifier after var")
            return nil
        }
        
        while true {
            let name = currentToken?.raw
            nextToken() // eat id
            
            var `init`: Expr?
            if .operator(.equals) == currentToken {
                nextToken() // eat =
                
                `init` = self.parseExpression()
                if `init` == nil { return nil }
            }
            varNames.append(.init(name!, `init`!))

            if .mark(.comma) != currentToken { break }
            nextToken() // eat ,

            if case .identifier = currentToken {
            } else {
                printE("expected identifier list after var")
                return nil
            }
        }

        if .keyword(.in) != currentToken {
            printE("expected 'in' keyword after 'var'")
            return nil
        }
        nextToken() // eat in
        
        guard let body = self.parseExpression() else { return nil }
        return .var(varNames, body)
    }
}

//===----------------------------------------------------------------------===//
// Top-Level parsing
//===----------------------------------------------------------------------===//

//extension Parser.Iterator {
//    func handleDefinition() {
//        if let _ = self.parseDefinition() {
//            printE("Parsed a function definition.\n")
//        } else {
//            _ = self.nextToken()
//        }
//    }
//
//    func handleExtern() {
//        if let _ = self.parseExtern() {
//            printE("Parsed an extern\n")
//        } else {
//            _ = self.nextToken()
//        }
//    }
//
//    func handleTopLevelExpression() {
//        if let _ = self.parseTopLevelExpr() {
//            printE("Parsed a top-level expr\n")
//        } else {
//            _ = self.nextToken()
//        }
//    }
//}
