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
    
    func run() throws {
        let code = try String(contentsOfFile: self.file)
        Parser(input: code).forEach { (expr) in
            expr.codeGen()?.dump()
        }
        /// x86_64-apple-darwin19.5.0
        let machine = try TargetMachine(triple: .default, cpu: "x86-64", features: "", optLevel: .default, relocations: .default, codeModel: .default)
        module.targetTriple = .default
        module.dataLayout = machine.dataLayout
        passPipeliner.execute()
        try machine.emitToFile(module: module, type: .object, path: self.output)
    }
}
