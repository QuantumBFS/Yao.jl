using Yao
using BenchmarkTools

using Yao.Intrinsics
using Yao.LuxurySparse
import Yao.Intrinsics: basis

include("swap.jl")

msk = bmask(2,5)
state = rand(ComplexF64, 1<<16, 1)

bench = BenchmarkGroup()
bg = bench["Basis"] = BenchmarkGroup()
bg["swap"] = @benchmarkable swapbits2(236, $msk)

bg = bench["SwapGate"] = BenchmarkGroup()
bg["matrix"] = @benchmarkable swapgate(ComplexF64, 16, 3, 7)
bg["apply-mat"] = @benchmarkable swapapply!($(state), 7, 3)
bg["apply-vec"] = @benchmarkable swapapply!($(vec(state)), 7, 3)

#bg = bench["SingleControlXYZ"] = BenchmarkGroup()
#@benchmark cyapply!(s, 7, 1, 3)
#@benchmark czapply!(s, 7, 1, 3)
#@benchmark cxapply!(s, 15, 13, 3)
#@benchmark cxapply!(s, (7, 2), (1, 0), 3)
#@benchmark cyapply!(s, (7, 2), (1, 0), 3)
#@benchmark czapply!(s, (7, 2), (1, 0), 3)

showall(run(bench, verbose=true))
