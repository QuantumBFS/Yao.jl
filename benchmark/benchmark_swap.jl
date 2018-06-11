using Yao
using BenchmarkTools

using Yao.Intrinsics
using Yao.LuxurySparse
import Yao.Intrinsics: basis

include("swap.jl")

msk = bmask(2,5)
state = rand(Complex128, 1<<16, 1)

bench = BenchmarkGroup()
bg = bench["Basis"] = BenchmarkGroup()
bg["swap"] = @benchmarkable swapbits2(236, $msk)

bg = bench["SwapGate"] = BenchmarkGroup()
bg["matrix"] = @benchmarkable swapgate(Complex128, 16, 3, 7)
bg["apply-mat"] = @benchmarkable swapapply!($(state), 7, 3)
bg["apply-vec"] = @benchmarkable swapapply!($(vec(state)), 7, 3)

showall(run(bench, verbose=true))
