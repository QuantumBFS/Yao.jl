using Yao
using Yao.Intrinsics
################## Benchmarks #################
using BenchmarkTools
v = collect(0:1<<16-1)
orders = randperm(16)
#bres = @benchmark  reorder($v, $orders)
#@code_warntype  collect((reordered_basis(16, orders)))
#bres = @benchmark  collect((reordered_basis(16, orders)))
#bres = @benchmark  collect((reordered_basis(16, orders)))
Pm = pmrand(1<<16)
#@benchmark $Pm |> invorder
Dv = Diagonal(v)
@benchmark $Dv |> invorder
