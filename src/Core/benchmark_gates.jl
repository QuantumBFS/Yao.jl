using BenchmarkTools
include("basis.jl")
include("gates.jl")

bss = basis(16)
bg = BenchmarkGroup()
bg["X"] = @benchmarkable xgate(2, bss)
bg["Y"] = @benchmarkable ygate(2, bss)
bg["Z"] = @benchmarkable zgate(2, bss)
showall(run(bg, verbose=true))
