import Foundation

@_silgen_name("putchard")
func putchard(_ a: Double) -> Double {
    fputc(Int32(a), stderr)
    return 0
}

@_silgen_name("printdesity")
func printdesity(_ a: Double) -> Double {
    fputs("\(a)", stderr)
    return 0
}

@_silgen_name("mandel")
@discardableResult
func mandel(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double 

mandel(-2.3, -1.3, 0.05, 0.07)
print("")
mandel(-2, -1, 0.02, 0.04)
print("")
mandel(-0.9, -1.4, 0.02, 0.03)