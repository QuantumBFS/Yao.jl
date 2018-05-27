using BenchmarkTools
include("basis.jl")
include("gates.jl")
include("utils.jl")

v = randn(Complex128, 1<<16)
bg = BenchmarkGroup()
xg = xgate(16, 2)
#bg["indices_with"] = @benchmarkable indices_with(2, bss)
bg["X"] = @benchmarkable xgate(16, 2)
bg["Y"] = @benchmarkable ygate(16, 2)
bg["Z"] = @benchmarkable zgate(16, 2)
bg["X*v"] = @benchmarkable $xg * v
showall(run(bg, verbose=true))
