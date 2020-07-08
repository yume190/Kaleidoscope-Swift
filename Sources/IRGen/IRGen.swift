import LLVM
import AST
import Tool
import Parser

public final class Contexts {
    public let context: Context
    public let module: Module
    public let builder: IRBuilder
    public let passPipeliner: PassPipeliner
    
    fileprivate var namedValues: [String:IRValue] = [:]
    fileprivate var functionProtos: [String: Function] = [:]
    
    public init(isActiveOptimizerPass: Bool = true) {
        self.context = Context()
        self.module = Module(name: "name", context: context)
        self.builder = .init(module: module)
        self.passPipeliner = .init(module: module)
        
        if isActiveOptimizerPass {
            self.activeOptimizerPass()
        }
    }
    
    #warning("TODO")
    func getFunction(name: String) -> Function {
        return module.function(named: name)!
    }
    
    /// L4 Optimizer Pass
    private final func activeOptimizerPass() {
        passPipeliner.addStage("YumeOptimizeStatge") { builder in
            builder.add(Pass.instructionCombining)
            builder.add(Pass.reassociate)
            builder.add(Pass.gvn)
            builder.add(Pass.cfgSimplification)
        }
        // TheFPM->doInitialization();
    }
    public func codeGen(input: String) {
        Parser(input: input).forEach { (expr) in
            _ = expr.codeGen(self)
        }
    }
    
    public func dump(input: String) {
        Parser(input: input).forEach { (expr) in
            expr.codeGen(self)?.dump()
        }
    }
}

extension Expr {
    func codeGen(_ contexts: Contexts) -> IRValue? {
        switch self {
        case .number(let num):
            return FloatType.double.constant(num)
        case .variable(let variable):
            guard let v = contexts.namedValues[variable] else {
                printE("Unknown variable name")
                return nil
            }
            return v
        case let .binary(lhs, op, rhs):
            guard let l = lhs.codeGen(contexts) else {return nil}
            guard let r = rhs.codeGen(contexts) else {return nil}
            
            switch op {
            case .plus:
                return contexts.builder.buildAdd(l, r, name: "addtmp")
            case .minus:
                return contexts.builder.buildSub(l, r, name: "subtmp")
            case .times:
                return contexts.builder.buildMul(l, r, name: "multmp")
            case .less:
                let aa = contexts.builder.buildFCmp(l, r, .unorderedLessThan, name: "cmptmp")
                return contexts.builder.buildIntToFP(aa, type: FloatType.double, signed: false, name: "booltmp")
//                return builder.buildFCmp(l, r, .orderedLessThan, name: "boolCmp")
//                case '<':
//                  L = Builder.CreateFCmpULT(L, R, "cmptmp");
//                  // Convert bool 0/1 to double 0.0 or 1.0
//                  return Builder.CreateUIToFP(L, Type::getDoubleTy(TheContext),
//                                              "booltmp");
            default:
                printE("invalid binary operator")
                return nil
//                break
            }
            
//            var fName = "binary"
//            fName.append(op.rawValue)
//            let f = contexts.getFunction(name: fName)
//            return contexts.builder.buildCall(f, args: [l, r], name: "binop")
        case let .call(name, args):
            
            guard let f: Function = contexts.module.function(named: name) else {
                printE("Unknown function referenced")
                return nil
            }
            
            guard f.parameters.count == args.count else {
                printE("Incorrect # arguments passed")
                return nil
            }
                
            var _args: [IRValue] = []
            for arg in args {
                guard let genedCode = arg.codeGen(contexts) else {
                    return nil
                }
                _args.append(genedCode)
            }
              
            return contexts.builder.buildCall(f, args: _args, name: "calltmp")
        case let .prototype(proto):
            let argTypes = [IRType](repeating: FloatType.double,
                                    count: proto.arguments.count)
            let funcType = FunctionType(argTypes, FloatType.double)
            let function = contexts.builder.addFunction(proto.name, type: funcType)

            for (var param, name) in zip(function.parameters, proto.arguments) {
                param.name = name
            }

            return function
        case let .function(proto, expr):
            guard let function: Function = contexts.module.function(named: proto.name) ?? Expr.prototype(proto).codeGen(contexts) as? Function else {return nil}
            
            let entryBlock = function.appendBasicBlock(named: "entry")
            contexts.builder.positionAtEnd(of: entryBlock)
            
            contexts.namedValues.removeAll()
            for arg in function.parameters {
                contexts.namedValues[arg.name] = arg
            }
            
            if let retValue = expr.codeGen(contexts) {
                contexts.builder.buildRet(retValue)
                
                // Validate the generated code, checking for consistency.
//                verifyFunction(*TheFunction);

                /// L4 JIT
                // Optimize the function.
                // TheFPM->run(*TheFunction);
                contexts.passPipeliner.execute()

                return function
            }
            
            // Error reading body, remove function.
            function.eraseFromParent()
            return nil
        case let .if(cond, then, `else`):
            guard let condV = cond.codeGen(contexts) else { return nil }
            
            let condV2 = contexts.builder.buildFCmp(condV, FloatType.double.constant(0), .orderedNotEqual, name: "ifcond")
            guard let theFunction = contexts.builder.insertBlock?.parent else {return nil}
            
            let thenBB = theFunction.appendBasicBlock(named: "then", in: contexts.context)
            let elseBB = BasicBlock(context: contexts.context, name: "else")
            let mergeBB = BasicBlock(context: contexts.context, name: "ifcont")
            contexts.builder.buildCondBr(condition: condV2, then: thenBB, else: elseBB)
            
            // Emit then value.
            contexts.builder.positionAtEnd(of: thenBB)
            guard let thenV = then.codeGen(contexts) else {return nil}
            contexts.builder.buildBr(mergeBB)
            // Codegen of 'Then' can change the current block, update ThenBB for the PHI.
            let thenBB2 = contexts.builder.insertBlock
            
            // Emit else block.
            theFunction.append(elseBB)
            contexts.builder.positionAtEnd(of: elseBB)
            guard let elseV = `else`.codeGen(contexts) else {return nil}
            contexts.builder.buildBr(mergeBB)
            // Codegen of 'Else' can change the current block, update ElseBB for the PHI.
            let elseBB2 = contexts.builder.insertBlock
            
            // Emit merge block.
            theFunction.append(mergeBB)
            contexts.builder.positionAtEnd(of: mergeBB)
//            PHINode *PN = Builder.CreatePHI(Type::getDoubleTy(TheContext), 2, "iftmp");
            let pn = contexts.builder.buildPhi(FloatType.double, name: "iftmp")
            
            pn.addIncoming([
                (thenV, thenBB2!),
                (elseV, elseBB2!)
            ])
            
            return pn
            
        case let .for(name, start, end, step, body):
            guard let startV = start.codeGen(contexts) else { return nil }
            
            guard let theFunction = contexts.builder.insertBlock?.parent else {return nil}
            let preheaderBB = contexts.builder.insertBlock
            let loopBB = theFunction.appendBasicBlock(named: "loop", in: contexts.context)
            contexts.builder.buildBr(loopBB)
            
            contexts.builder.positionAtEnd(of: loopBB)
            let variable = contexts.builder.buildPhi(FloatType.double, name: name)
            variable.addIncoming([(startV, preheaderBB!)])
            
            let oldValue = contexts.namedValues[name]
            contexts.namedValues[name] = variable

            guard let _ = body.codeGen(contexts) else { return nil }
            var stepV: IRValue?
            if let _step = step {
                stepV = _step.codeGen(contexts)
                if stepV == nil {return nil}
            } else {
                /// APFloat(1.0)
                stepV = FloatType.double.constant(1)
            }
            
            let nextVar = contexts.builder.buildAdd(variable, stepV!, name: "nextvar")
            
            guard let endV = end.codeGen(contexts) else { return nil }
            
            let endV2 = contexts.builder.buildFCmp(endV, FloatType.double.constant(0), .orderedNotEqual, name: "loopcond")
            
            let loopEndBB = contexts.builder.insertBlock
            let afterBB = theFunction.appendBasicBlock(named: "afterloop", in: contexts.context)
            contexts.builder.buildCondBr(condition: endV2, then: loopBB, else: afterBB)
            contexts.builder.positionAtEnd(of: afterBB)
            variable.addIncoming([(nextVar, loopEndBB!)])
            if let oldValue = oldValue {
                contexts.namedValues[name] = oldValue
            } else {
                contexts.namedValues.removeValue(forKey: name)
            }
            return FloatType.double.constant(0)
        }
    }
}
