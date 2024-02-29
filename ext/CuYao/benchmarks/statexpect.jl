using CuYao
using Yao
using BenchmarkTools

sf(x, y) = abs(x-y)
a = randn(1024)
ca = a |> cu
b = randn(1024)
cb = b |> cu
@benchmark expect(StatFunctional{2}(sf), a, b) seconds=2
@benchmark expect(StatFunctional{2}(sf), a) seconds=2
@benchmark expect(StatFunctional{2}(sf), ca, cb) seconds=2
@benchmark expect(StatFunctional{2}(sf), ca) seconds=2
