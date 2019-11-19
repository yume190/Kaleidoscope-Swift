import Foundation
public protocol ExprAST: class {
//    init()
}

/// NumberExprAST - Expression class for numeric literals like "1.0".
public class NumberExprAST: ExprAST {
    let val: Double
    public init(val: Double) {
        self.val = val
    }
}

/// VariableExprAST - Expression class for referencing a variable, like "a".
public class VariableExprAST: ExprAST {
    let name: String
    public init(name: String) {
        self.name = name
    }
}

/// BinaryExprAST - Expression class for a binary operator.
public class BinaryExprAST: ExprAST {
    let op: Character
    let lhs: ExprAST
    let rhs: ExprAST
    public init(op: Character, lhs: ExprAST, rhs: ExprAST) {
        self.op = op
        self.lhs = lhs
        self.rhs = rhs
    }
}

/// CallExprAST - Expression class for function calls.
public class CallExprAST: ExprAST {
    // std::string Callee;
    // std::vector<std::unique_ptr<ExprAST>> Args;
    let callee: String
    let args: [ExprAST]
    public init(callee: String, args: [ExprAST]) {
        self.callee = callee
        self.args = args
    }
}

/// PrototypeAST - This class represents the "prototype" for a function,
/// which captures its name, and its argument names (thus implicitly the number
/// of arguments the function takes).
public class PrototypeAST: ExprAST {
    // std::string Name;
    // std::vector<std::string> Args;
    let name: String
    let args: [String]
    public init(name: String, args: [String]) {
        self.name = name
        self.args = args
    }
}

/// FunctionAST - This class represents a function definition itself.
public class FunctionAST: ExprAST {
    // std::unique_ptr<PrototypeAST> Proto;
    // std::unique_ptr<ExprAST> Body;
    let proto: PrototypeAST
    let body: ExprAST
    public init(proto: PrototypeAST, body: ExprAST) {
        self.proto = proto
        self.body = body
    }
}
