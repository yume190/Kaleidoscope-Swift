// @_cdecl("average")
@_silgen_name("average")
func average(_ a: Double, _ b: Double) -> Double

@_silgen_name("add")
func add(_ a: Double, _ b: Double) -> Double {
    a + b + 2
}

print(average(10, 20))