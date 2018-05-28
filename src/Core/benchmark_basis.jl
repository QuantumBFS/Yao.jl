####### Benchmark notes #######
# [2 for x in 1:10] much faster than repeat([2], outer=10)
# reduce(+, [1,2,3]) much faster than +([1,2,3]...)
# collect(1:10) much faster than [1:10...]
# x[:] = xor.(x, 3) is slower than xor(x, 3)
#
# x & 0x1 similar to x & 1
# xor.(1, 2) similar to xor(1, 2)
#
# TODO
# benchmark construction and taking in `indices_with` function.

using BenchmarkTools
include("basis.jl")

bench = BenchmarkGroup()
bg = bench["Basis"] = BenchmarkGroup()
bg["takebit-Int"] = @benchmarkable takebit.($(basis(16)), 3)
#bg["takebit-UInt"] = @benchmarkable takebit.($(basis(16)), 3)

showall(run(bench, verbose=true))
