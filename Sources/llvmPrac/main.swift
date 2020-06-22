import Lexer
import AST
import Parser
import IRGen
import LLVM
import Foundation

func readFile(_ path: String) -> String? {
    var path = path
    if path.hasSuffix("\n") {
        path.removeLast()
    }
    guard path.split(separator: ".").last! == "k" else {
        print("Expected file is *.k.")
        return nil
    }
    do {
        return try String(contentsOfFile: path, encoding: .utf8)
    } catch {
        print("Read file \(path) failure.")
        return nil
    }
}

print(CommandLine.arguments)
let path = CommandLine.arguments.last!
//guard let path = String(data: FileHandle.standardInput.availableData, encoding: .utf8) else {exit(1)}
guard let code = readFile(path) else {exit(1)}

Parser(input: code).forEach { (expr) in
    expr.codeGen()?.dump()
}
/// x86_64-apple-darwin19.5.0
let machine = try TargetMachine(triple: .default, cpu: "x86-64", features: "", optLevel: .default, relocations: .default, codeModel: .default)
module.targetTriple = .default
module.dataLayout = machine.dataLayout
passPipeliner.execute()
try machine.emitToFile(module: module, type: .object, path: "output.o")
