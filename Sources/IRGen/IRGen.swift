import LLVM
import AST

public extension Expr {
    func codeGen() -> Value? {
        switch self {
        case .number(let num):
            return FloatType.double.constant(num)
        case .variable(let variable):
            guard let v = namedValues[variable] else {
//                LogErrorV("Unknown variable name");
                return nil
            }
            return v
        case let .binary(lhs, op, rhs):
            guard let l = lhs.codeGen() else {return nil}
            guard let r = rhs.codeGen() else {return nil}
            
            switch op {
            case .plus:
                return Gen.main.builder.buildAdd(l, r, name: "addtmp")
            case .minus:
                return Gen.main.builder.buildSub(l, r, name: "subtmp")
            case .times:
                return Gen.main.builder.buildMul(l, r, name: "multmp")
            case .less:
                let aa = Gen.main.builder.buildFCmp(l, r, .orderedLessThan, name: "cmptmp")
                return Gen.main.builder.buildIntToFP(aa, type: FloatType.double, signed: false, name: "booltmp")
//                case '<':
//                  L = Builder.CreateFCmpULT(L, R, "cmptmp");
//                  // Convert bool 0/1 to double 0.0 or 1.0
//                  return Builder.CreateUIToFP(L, Type::getDoubleTy(TheContext),
//                                              "booltmp");
            default:
                return nil
//                  return LogErrorV("invalid binary operator");
            }
        case let .call(name, args):
            
            guard let f: Function = Gen.main.module.function(named: name) else {
//                return LogErrorV("Unknown function referenced");
                return nil
            }
            
//            if (CalleeF->arg_size() != Args.size())
            guard f.parameters.count == args.count else {
//                return LogErrorV("Incorrect # arguments passed");
                return nil
            }
                
            var _args: [IRValue] = []
            for arg in args {
                guard let genedCode = arg.codeGen() else {
                    return nil
                }
                _args.append(genedCode)
            }
              
            return Gen.main.builder.buildCall(f, args: _args)
        case let .prototype(name, params):            
//            if let function = Gen.main.module.function(named: name) {
//                return function
//            }
            let argTypes = [IRType](repeating: FloatType.double,
                                    count: params.count)
            let funcType = FunctionType(argTypes, FloatType.double)
            let function = Gen.main.builder.addFunction(name, type: funcType)

            for (var param, name) in zip(function.parameters, params) {
                param.name = name
            }

            return function
        case let .function(name, params, expr):
            guard let function: Function = Gen.main.module.function(named: name) ?? Expr.prototype(name, params).codeGen() as? Function else {return nil}
            
            
//            Gen.main.builder.buildBr(BasicBlock.)
//            let bb = Gen.main.builder.buildBr(BasicBlock.init(context: Gen.main.context, name: "entry"))
//            Gen.main.builder.insert(bb)
            let entryBlock = function.appendBasicBlock(named: "entry")
            Gen.main.builder.positionAtEnd(of: entryBlock)
            
            namedValues.removeAll()
            for arg in function.parameters {
                namedValues[arg.name] = arg
            }
            
            if let retValue = expr.codeGen() {
                Gen.main.builder.buildRet(retValue)
                
                // Validate the generated code, checking for consistency.
//                verifyFunction(*TheFunction);

                /// L4 JIT
                // // Optimize the function.
                // TheFPM->run(*TheFunction);
                Gen.main.passPipeliner.execute()

                return function
            }
            
            // Error reading body, remove function.
            function.eraseFromParent()
            return nil
        default:
            return nil
        }
    }
}

public typealias Value = IRValue
var namedValues: [String:Value] = [:]

public var isAddOptimizerPass: Bool = false
enum Gen {
    static let main: IR = IR(name: "name")

    public class IR {
        let context = Context()
        let module: Module
        let builder: IRBuilder
        /// L4 Optimizer Pass
        let passPipeliner: PassPipeliner
    
        init(name: String) {
            self.module = Module(name: name, context: self.context)
            self.builder = IRBuilder(module: self.module)

            /// L4 Optimizer Pass
            if isAddOptimizerPass {
                self.passPipeliner = PassPipeliner(module: module)
                self.passPipeliner.addStage("YumeOptimizeStatge") { builder in
                    builder.add(Pass.instructionCombining)
                    builder.add(Pass.reassociate)
                    builder.add(Pass.gvn)
                    builder.add(Pass.cfgSimplification)
                }
                // TheFPM->doInitialization();
            }
        }
    }
}
