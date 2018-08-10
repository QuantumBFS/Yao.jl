using Yao.Intrinsics
using BenchmarkTools

for nbit in 1:5:
    n=1<<nbit
    const v = randn(ComplexF64, 1<<16)
    const un = randn(n,n)
    const sun = SMatrix{n,n}(u4)
    const inds =  randperm(n) +18
    const sinds = SVector{n}(inds4)

    if nbit==1
        @benchmark u1rows!($v, $(inds[1]), $(inds[2]), $(un[1]), $(un[3]), $(un[2]), $(un[4]))
    end
    @benchmark unrows!($v, $inds, $un)
    @benchmark unrows!($v, $sinds, $sun)
end
