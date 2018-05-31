using BenchmarkTools

using Yao
import Yao: xapply!, yapply!, zapply!, cxapply!, cyapply!, czapply!

state = randn(Complex128, 1<<16, 1)
bench = BenchmarkGroup()
xg = xgate(16, 2)
bg = bench["XYZ Gate"] = BenchmarkGroup()
bg["X"] = @benchmarkable xapply!($(vec(state)), 2)
bg["Y"] = @benchmarkable xapply!($(vec(state)), 2)
bg["Z"] = @benchmarkable xapply!($(vec(state)), 2)
bg = bench["Control-XYZ Gate"] = BenchmarkGroup()
bg["CX"] = @benchmarkable cxapply!($(vec(state)), 7, 3)
bg["CY"] = @benchmarkable cyapply!($(vec(state)), 7, 3)
bg["CZ"] = @benchmarkable czapply!($(vec(state)), 7, 3)
showall(run(bench, verbose=true))
