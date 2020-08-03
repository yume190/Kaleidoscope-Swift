//
//  Command.swift
//  ArgumentParser
//
//  Created by Yume on 2020/3/10.
//

import ArgumentParser
import Lexer
import AST
import Parser
import IRGen
import LLVM
import Foundation

struct Command: ParsableCommand {
    @Argument(help: "input kaleiscope file")
    var file: String
    
    @Option(name: .shortAndLong, help: "compiled out object file")
    var output: String = "output.o"
    
    @Flag(name: [.customLong("ir", withSingleDash: true)], help: "generate ir")
    var isGenerateIR = false
    
    @Flag(name: [.customLong("op", withSingleDash: true)], help: "add op pass")
    var optimize = false
    
    func run() throws {
        let code = try String(contentsOfFile: self.file)
        let contexts = Contexts(isActiveOptimizerPass: optimize)
        if isGenerateIR {
            let url = URL(fileURLWithPath: output)
            let ll = contexts.pipe(input: code)
            try ll.write(to: url, atomically: true, encoding: .utf8)
            return
        }
        contexts.codeGen(input: code)
        
        // MARK: Target & Feature
        //* llvm-as < /dev/null | llc -march=x86 -mattr=help
        /// x86_64-apple-darwin19.5.0
//        let cpu = "generic"
        let cpu = "x86-64"
        let features = ""
        let machine = try TargetMachine(triple: .default, cpu: cpu, features: features, optLevel: .default, relocations: .default, codeModel: .default)
        contexts.module.targetTriple = .default
        contexts.module.dataLayout = machine.dataLayout
        contexts.passPipeliner.execute()
        try machine.emitToFile(module: contexts.module, type: .object, path: self.output)
    }
}

// struct DebugInfo {
//     // DICompileUnit
//     let cu: CompileUnitMetadata
//     let dblTy: DIType?
// //    DIType *getDoubleTy();
//     var getDoubleTy: DIType {
//         if let dblTy = dblTy {
//             return dblTy
//         }
//         // DBuilder->createBasicType("double", 64, dwarf::DW_ATE_float);
//         return DIBuilder(module: Module.init(name: "")).buildBasicType(named: "double", encoding: .float, flags: .accessibility, size: 64)
//     }
// }


// func abc() {
//     let builder = DIBuilder(module: Module.init(name: ""))
    
// //    DBuilder->createCompileUnit(
// //        dwarf::DW_LANG_C,
// //        DBuilder->createFile("fib.ks", "."),
// //        "Kaleidoscope Compiler", producer: String
// //        0, isOptimized: Bool ok
// //        "", Flags: String ok
// //        0); RV : unsigned ok runtime version
//     builder.buildCompileUnit(
//         for: .c,
//         in: builder.buildFile(named: "fib.ks", in: "."),
//         kind: .full // fulldebug
//     )
//     builder.finalize()
    
//     let di: DebugInfo? = nil
//     di!.cu.file
//     di!.cu.file?.directory
//     // builder.buildFile(named: <#T##String#>, in: <#T##String#>)
// }
