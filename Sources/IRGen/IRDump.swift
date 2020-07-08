//
//  IRDump.swift
//  IRGen
//
//  Created by Yume on 2019/12/3.
//

import Foundation
import LLVM

fileprivate let endBytes: [UInt8] = [0x7d, 0x0a]

/// https://phatbl.at/2019/01/08/intercepting-stdout-in-swift.html
/// https://medium.com/@thesaadismail/eavesdropping-on-swifts-print-statements-57f0215efb42
extension IRValue {
    /// must use `RunLoop.main.run()` to enble GCD
    public func pipe() -> String {
        let group = DispatchGroup()
        var tempData = Data()
        let _pipe = Pipe()

//        setvbuf(stderr, nil, _IONBF, 0)
        dup2(_pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        group.enter()
        _pipe.fileHandleForReading.readabilityHandler = { stdErrFileHandle in
            let stdErrPartialData = stdErrFileHandle.availableData

            tempData.append(stdErrPartialData)
            let end: [UInt8] = tempData.suffix(2)
            if end == endBytes {
                group.leave()
            }
        }

        self.dump()

        _ = group.wait(timeout: .now() + DispatchTimeInterval.seconds(1))
        
        return String(data: tempData, encoding: .utf8) ?? ""
    }
}
