import LLVM
import AST

fileprivate var namedValues: [String:IRValue] = [:]

public extension Expr {
    func codeGen() -> IRValue? {
        switch self {
        case .number(let num):
            return FloatType.double.constant(num)
        case .variable(let variable):
            guard let v = namedValues[variable] else {
                printE("Unknown variable name")
                return nil
            }
            return v
        case let .binary(lhs, op, rhs):
            guard let l = lhs.codeGen() else {return nil}
            guard let r = rhs.codeGen() else {return nil}
            
            switch op {
            case .plus:
                return builder.buildAdd(l, r, name: "addtmp")
            case .minus:
                return builder.buildSub(l, r, name: "subtmp")
            case .times:
                return builder.buildMul(l, r, name: "multmp")
            case .less:
                let aa = builder.buildFCmp(l, r, .orderedLessThan, name: "cmptmp")
                return builder.buildIntToFP(aa, type: FloatType.double, signed: false, name: "booltmp")
//                case '<':
//                  L = Builder.CreateFCmpULT(L, R, "cmptmp");
//                  // Convert bool 0/1 to double 0.0 or 1.0
//                  return Builder.CreateUIToFP(L, Type::getDoubleTy(TheContext),
//                                              "booltmp");
            default:
                printE("invalid binary operator")
                return nil
            }
        case let .call(name, args):
            
            guard let f: Function = module.function(named: name) else {
                printE("Unknown function referenced")
                return nil
            }
            
            guard f.parameters.count == args.count else {
                printE("Incorrect # arguments passed")
                return nil
            }
                
            var _args: [IRValue] = []
            for arg in args {
                guard let genedCode = arg.codeGen() else {
                    return nil
                }
                _args.append(genedCode)
            }
              
            return builder.buildCall(f, args: _args, name: "calltmp")
        case let .prototype(name, params):
            let argTypes = [IRType](repeating: FloatType.double,
                                    count: params.count)
            let funcType = FunctionType(argTypes, FloatType.double)
            let function = builder.addFunction(name, type: funcType)

            for (var param, name) in zip(function.parameters, params) {
                param.name = name
            }

            return function
        case let .function(name, params, expr):
            guard let function: Function = module.function(named: name) ?? Expr.prototype(name, params).codeGen() as? Function else {return nil}
            
            let entryBlock = function.appendBasicBlock(named: "entry")
            builder.positionAtEnd(of: entryBlock)
            
            namedValues.removeAll()
            for arg in function.parameters {
                namedValues[arg.name] = arg
            }
            
            if let retValue = expr.codeGen() {
                builder.buildRet(retValue)
                
                // Validate the generated code, checking for consistency.
//                verifyFunction(*TheFunction);

                /// L4 JIT
                // Optimize the function.
                // TheFPM->run(*TheFunction);
                passPipeliner.execute()

                return function
            }
            
            // Error reading body, remove function.
            function.eraseFromParent()
            return nil
        case let .if(cond, then, `else`):
            guard let condV = cond.codeGen() else { return nil }
            
            let condV2 = builder.buildFCmp(condV, FloatType.double.constant(0), .orderedNotEqual, name: "ifcond")
            guard let theFunction = builder.insertBlock?.parent else {return nil}
            
            let thenBB = theFunction.appendBasicBlock(named: "then", in: context)
            let elseBB = BasicBlock(context: context, name: "else")
            let mergeBB = BasicBlock(context: context, name: "ifcont")
            builder.buildCondBr(condition: condV2, then: thenBB, else: elseBB)
            
            // Emit then value.
            builder.positionAtEnd(of: thenBB)
            guard let thenV = then.codeGen() else {return nil}
            builder.buildBr(mergeBB)
            // Codegen of 'Then' can change the current block, update ThenBB for the PHI.
            let thenBB2 = builder.insertBlock
            
            // Emit else block.
            theFunction.append(elseBB)
            builder.positionAtEnd(of: elseBB)
            guard let elseV = `else`.codeGen() else {return nil}
            builder.buildBr(mergeBB)
            // Codegen of 'Else' can change the current block, update ElseBB for the PHI.
            let elseBB2 = builder.insertBlock
            
            // Emit merge block.
            theFunction.append(mergeBB)
            builder.positionAtEnd(of: mergeBB)
//            PHINode *PN = Builder.CreatePHI(Type::getDoubleTy(TheContext), 2, "iftmp");
            let pn = builder.buildPhi(FloatType.double, name: "iftmp")
            
            pn.addIncoming([
                (thenV, thenBB2!),
                (elseV, elseBB2!)
            ])
            
            return pn
        }
    }
}
