using BenchmarkTools
include("basis.jl")
include("gates.jl")
include("utils.jl")

bss = basis(16)
v = randn(Complex128, 1<<16)
bg = BenchmarkGroup()
xg = xgate(2, bss)
#bg["indices_with"] = @benchmarkable indices_with(2, bss)
bg["X"] = @benchmarkable xgate(2, $bss)
bg["Y"] = @benchmarkable ygate(2, $bss)
bg["Z"] = @benchmarkable zgate(2, $bss)
bg["X*v"] = @benchmarkable $xg * v
showall(run(bg, verbose=true))
