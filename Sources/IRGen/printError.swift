//
//  File.swift
//  
//
//  Created by Yume on 2020/6/19.
//

import Foundation
import func Darwin.fputs
import var Darwin.stderr

fileprivate struct StderrOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

fileprivate var standardError = StderrOutputStream()

public func printE(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator, to: &standardError)
}
