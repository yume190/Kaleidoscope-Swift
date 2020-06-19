////
////  File.swift
////
////
////  Created by Yume on 2020/6/19.
////
//
//import LLVM
//import AST
//import Foundation
//
//public protocol IRGenable {
//    func codeGen() -> IRValue?
//}
//
//extension Expressionable {
//    public func codeGen() -> IRValue? {
//        return (self as? IRGenable)?.codeGen()
//    }
//}
//
//extension NumberAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        return FloatType.double.constant(self.value)
//    }
//}
//
//extension VariableAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        guard let v = namedValues[name] else {
//            printE("Unknown variable name")
//            return nil
//        }
//        return v
//    }
//}
//
//extension BinaryAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        guard let l = lhs.codeGen() else {return nil}
//        guard let r = rhs.codeGen() else {return nil}
//        
//        switch op {
//        case .plus:
//            return builder.buildAdd(l, r, name: "addtmp")
//        case .minus:
//            return builder.buildSub(l, r, name: "subtmp")
//        case .times:
//            return builder.buildMul(l, r, name: "multmp")
//        case .less:
//            let aa = builder.buildFCmp(l, r, .orderedLessThan, name: "cmptmp")
//            return builder.buildIntToFP(aa, type: FloatType.double, signed: false, name: "booltmp")
//            //                case '<':
//            //                  L = Builder.CreateFCmpULT(L, R, "cmptmp");
//            //                  // Convert bool 0/1 to double 0.0 or 1.0
//            //                  return Builder.CreateUIToFP(L, Type::getDoubleTy(TheContext),
//        default:
//            printE("invalid binary operator")
//            return nil
//        }
//    }
//}
//
//extension CallAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        guard let function: Function = module.function(named: self.callee) else {
//            printE("Unknown function referenced")
//            return nil
//        }
//        
//        guard function.parameters.count == args.count else {
//            printE("Incorrect # arguments passed")
//            return nil
//        }
//        
//        var _args: [IRValue] = []
//        for arg in args {
//            guard let genedCode = arg.codeGen() else {
//                return nil
//            }
//            _args.append(genedCode)
//        }
//        
//        return builder.buildCall(function, args: _args, name: "calltmp")
//    }
//}
//
//extension PrototypeAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        let argTypes = [IRType](repeating: FloatType.double,
//                                count: args.count)
//        let funcType = FunctionType(argTypes, FloatType.double)
//        let function = builder.addFunction(name, type: funcType)
//        
//        for (var param, name) in zip(function.parameters, args) {
//            param.name = name
//        }
//        
//        return function
//    }
//}
//
//extension FunctionAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        guard let function: Function = module.function(named: prototype.name) ?? Expr.prototype(prototype.name,prototype.args).codeGen() as? Function else {return nil}
//        
//        let entryBlock = function.appendBasicBlock(named: "entry")
//        builder.positionAtEnd(of: entryBlock)
//        
//        namedValues.removeAll()
//        for arg in function.parameters {
//            namedValues[arg.name] = arg
//        }
//        
//        if let retValue = expr.codeGen() {
//            builder.buildRet(retValue)
//            
//            // Validate the generated code, checking for consistency.
//            //                verifyFunction(*TheFunction);
//            
//            /// L4 JIT
//            // Optimize the function.
//            // TheFPM->run(*TheFunction);
//            passPipeliner.execute()
//            
//            return function
//        }
//        
//        // Error reading body, remove function.
//        function.eraseFromParent()
//        return nil
//    }
//}
//
//extension IfAST: IRGenable {
//    public func codeGen() -> IRValue? {
//        guard let condV = cond.codeGen() else { return nil }
//        
//        let condV2 = builder.buildFCmp(condV, FloatType.double.constant(0), .orderedNotEqual, name: "ifcond")
//        guard let theFunction = builder.insertBlock?.parent else {return nil}
//        
//        let thenBB = theFunction.appendBasicBlock(named: "then", in: context)
//        let elseBB = BasicBlock(context: context, name: "else")
//        let mergeBB = BasicBlock(context: context, name: "ifcont")
//        builder.buildCondBr(condition: condV2, then: thenBB, else: elseBB)
//        
//        // Emit then value.
//        builder.positionAtEnd(of: thenBB)
//        guard let thenV = then.codeGen() else {return nil}
//        builder.buildBr(mergeBB)
//        // Codegen of 'Then' can change the current block, update ThenBB for the PHI.
//        let thenBB2 = builder.insertBlock
//        
//        // Emit else block.
//        theFunction.append(elseBB)
//        builder.positionAtEnd(of: elseBB)
//        guard let elseV = `else`.codeGen() else {return nil}
//        builder.buildBr(mergeBB)
//        // Codegen of 'Else' can change the current block, update ElseBB for the PHI.
//        let elseBB2 = builder.insertBlock
//        
//        // Emit merge block.
//        theFunction.append(mergeBB)
//        builder.positionAtEnd(of: mergeBB)
//        //            PHINode *PN = Builder.CreatePHI(Type::getDoubleTy(TheContext), 2, "iftmp");
//        let pn = builder.buildPhi(FloatType.double, name: "iftmp")
//        
//        pn.addIncoming([
//            (thenV, thenBB2!),
//            (elseV, elseBB2!)
//        ])
//        
//        return pn
//    }
//}
