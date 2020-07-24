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
        
        /// x86_64-apple-darwin19.5.0
        let machine = try TargetMachine(triple: .default, cpu: "x86-64", features: "", optLevel: .default, relocations: .default, codeModel: .default)
        contexts.module.targetTriple = .default
        contexts.module.dataLayout = machine.dataLayout
        contexts.passPipeliner.execute()
        try machine.emitToFile(module: contexts.module, type: .object, path: self.output)
    }
}
