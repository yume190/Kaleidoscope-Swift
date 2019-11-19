//import Token
//
//public class File {
//    public private(set) var externs = [Prototype]()
//    public private(set) var definitions = [Definition]()
//    public private(set) var expressions = [Expr]()
//    public private(set) var prototypeMap = [String: Prototype]()
//
//    public init() {}
//    
//    func prototype(name: String) -> Prototype? {
//        return prototypeMap[name]
//    }
//
//    func addExpression(_ expression: Expr) {
//        expressions.append(expression)
//    }
//
//    func addExtern(_ prototype: Prototype) {
//        externs.append(prototype)
//        prototypeMap[prototype.name] = prototype
//    }
//
//    func addDefinition(_ definition: Definition) {
//        definitions.append(definition)
//        prototypeMap[definition.prototype.name] = definition.prototype
//    }
//}
//
