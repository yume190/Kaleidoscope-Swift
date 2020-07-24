import Foundation

@_silgen_name("putchard")
func putchard(_ a: Double) -> Double {
    fputc(Int32(a), stderr)
    return 0
}

@_silgen_name("printd")
func printdesity(_ a: Double) -> Double {
    fputs("\(a)\n", stderr)
    return 0
}


@_silgen_name("test")
@discardableResult
func test(_ a: Double) -> Double

test(123)
// print("")