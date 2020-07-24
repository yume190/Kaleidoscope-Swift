import LLVM
import AST
import Tool
import Parser
import Token
import Darwin
import Foundation

public final class Contexts {
    public let context: Context
    public let module: Module
    public let builder: IRBuilder
    public let passPipeliner: PassPipeliner
    
    fileprivate var namedValues: [String: IRInstruction] = [:]
    /// [String: PrototypeAST]
    fileprivate var functionProtos: [String: Prototype] = [:]
    fileprivate var binopPrecedence: [Character: Precedence] = [:]
    
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
    func getFunction(name: String) -> Function? {
        if let f = module.function(named: name) {
            return f
        }
        if let fi = self.functionProtos[name] {
            return Expr.prototype(fi).codeGen(self) as? Function
        }
        return nil
    }
    
    /// L4 Optimizer Pass
    private final func activeOptimizerPass() {
        passPipeliner.addStage("YumeOptimizeStatge") { builder in
            // Promote allocas to registers.
            builder.add(Pass.promoteMemoryToRegister)
            // Do simple "peephole" optimizations and bit-twiddling optzns.
            builder.add(Pass.instructionCombining)
            // Reassociate expressions.
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
    
    public func pipe(input: String) -> String {
        return Parser(input: input).compactMap { (expr) in
            return expr.codeGen(self)?.pipe()
        }.joined(separator: "")
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
            return contexts.builder.buildLoad(v, name: variable)
        case let .binary(lhs, op, rhs):
            if op == BinaryOperator.equals.rawValue {
                guard case let .variable(name) = lhs else {
                    printE("destination of '=' must be a variable")
                    return nil
                }
                guard let val = rhs.codeGen(contexts) else {return nil}
                guard let variable = contexts.namedValues[name] else {
                    printE("Unknown variable name \(name)")
                    return nil
                }
                contexts.builder.buildStore(val, to: variable)
                return val
            }
            
            guard let l = lhs.codeGen(contexts) else {return nil}
            guard let r = rhs.codeGen(contexts) else {return nil}
            
            switch op {
            case BinaryOperator.plus.rawValue:
                return contexts.builder.buildAdd(l, r, name: "addtmp")
            case BinaryOperator.minus.rawValue:
                return contexts.builder.buildSub(l, r, name: "subtmp")
            case BinaryOperator.times.rawValue:
                return contexts.builder.buildMul(l, r, name: "multmp")
            case BinaryOperator.less.rawValue:
                let aa = contexts.builder.buildFCmp(l, r, .unorderedLessThan, name: "cmptmp")
                return contexts.builder.buildIntToFP(aa, type: FloatType.double, signed: false, name: "booltmp")
//                return builder.buildFCmp(l, r, .orderedLessThan, name: "boolCmp")
//                case '<':
//                  L = Builder.CreateFCmpULT(L, R, "cmptmp");
//                  // Convert bool 0/1 to double 0.0 or 1.0
//                  return Builder.CreateUIToFP(L, Type::getDoubleTy(TheContext),
//                                              "booltmp");
            default:
//                printE("invalid binary operator")
//                return nil
                break
            }
            
            var fName = "binary"
            fName.append(op)
            let f = contexts.getFunction(name: fName)
            return contexts.builder.buildCall(f!, args: [l, r], name: "binop")
        case let .call(name, args):
            
            guard let f: Function = contexts.module.function(named: name) else {
                printE("Unknown function referenced: \(name)")
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
            contexts.functionProtos[proto.name] = proto
            
            guard let function = contexts.getFunction(name: proto.name) else {return nil}
            switch proto.kind {
            case .binary:
                contexts.binopPrecedence[proto.name.last ?? " "] = proto.precedence
            default:
                break
            }
            
            let entryBlock = function.appendBasicBlock(named: "entry")
            contexts.builder.positionAtEnd(of: entryBlock)
            
            contexts.namedValues.removeAll()
            for arg in function.parameters {
                let alloca = contexts.builder.buildAlloca(type: FloatType.double, count: 0, name: arg.name)
                contexts.builder.buildStore(arg, to: alloca)
                contexts.namedValues[arg.name] = alloca
            }
            
            if let retValue = expr.codeGen(contexts) {
                contexts.builder.buildRet(retValue)
                
                // Validate the generated code, checking for consistency.
                // verifyFunction(*TheFunction);

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
            guard let theFunction = contexts.builder.insertBlock?.parent else {return nil}

            let alloca = contexts.builder.buildAlloca(type: FloatType.double, count: 0, name: name)
            
            guard let startV = start.codeGen(contexts) else { return nil }
            contexts.builder.buildStore(startV, to: alloca)
            let preheaderBB = contexts.builder.insertBlock
            let loopBB = theFunction.appendBasicBlock(named: "loop", in: contexts.context)
            contexts.builder.buildBr(loopBB)
            
            contexts.builder.positionAtEnd(of: loopBB)
            let variable = contexts.builder.buildPhi(FloatType.double, name: name)
            variable.addIncoming([(startV, preheaderBB!)])
            
            let oldValue = contexts.namedValues[name]
            contexts.namedValues[name] = variable

            guard let _ = body.codeGen(contexts) else { return nil }
            
            var stepV: IRValue
            if let _step = step {
                if let _stepV = _step.codeGen(contexts) {
                    stepV = _stepV
                } else {
                    return nil
                }
            } else {
                /// APFloat(1.0)
                stepV = FloatType.double.constant(1)
            }
            
            guard let endV = end.codeGen(contexts) else { return nil }
            let curVar = contexts.builder.buildLoad(alloca)
//            let nextVar = contexts.builder.buildAdd(variable, stepV, name: "nextvar")
            let nextVar = contexts.builder.buildAdd(curVar, stepV, name: "nextvar")
            contexts.builder.buildStore(nextVar, to: alloca)
            
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
        case let .unary(op, operand):
            guard let operandV = operand.codeGen(contexts) else {return nil}
            
            var name = "unary"
            name.append(op)
            guard let f = contexts.getFunction(name: name) else {
                printE("Unknown unary operator")
                return nil
            }
            
            return contexts.builder.buildCall(f, args: [operandV], name: "unop")
        case let .var(names, body):
            var oldBindings: [IRInstruction] = []
//            let function = contexts.builder.insertBlock?.parent
            for name in names {
                let varName = name.first
                let `init` = name.second
                
                let initVal: IRValue
                
                if let _initVal = `init`.codeGen(contexts) {
                    initVal = _initVal
                } else {
                    return nil
                }
                
                let alloca = contexts.builder.buildAlloca(type: FloatType.double, count: 0, name: varName)
                contexts.builder.buildStore(initVal, to: alloca)
                oldBindings.append(contexts.namedValues[varName]!)
                
                contexts.namedValues[varName] = alloca
            }
            
            guard let bodyV = body.codeGen(contexts) else {return nil}
            
            for pair in names.enumerated() {
                contexts.namedValues[pair.element.first] = oldBindings[pair.offset]
            }
            
            return bodyV
        default:
            return nil
        }
    }
}
