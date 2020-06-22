//
//  File.swift
//  
//
//  Created by Yume on 2020/6/19.
//

import LLVM

public let context = Context()
public let module = Module(name: "name", context: context)
public let builder: IRBuilder = .init(module: module)
public let passPipeliner: PassPipeliner = .init(module: module)
/// L4 Optimizer Pass
public func activeOptimizerPass() {
    passPipeliner.addStage("YumeOptimizeStatge") { builder in
        builder.add(Pass.instructionCombining)
        builder.add(Pass.reassociate)
        builder.add(Pass.gvn)
        builder.add(Pass.cfgSimplification)
    }
    // TheFPM->doInitialization();
}
