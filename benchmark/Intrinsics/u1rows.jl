using Yao
using Yao.Intrinsics
using Random
using StaticArrays
using BenchmarkTools
using LuxurySparse

for ng in [1,2]
    n=1<<ng
    v = randn(ComplexF64, 1<<16)
    un = randn(n,n)
    sun = SMatrix{n,n}(un)
    inds =  randperm(n) .+18
    sinds = SVector{n}(inds)

    if ng==1
        println("u1rows(1)")
        display(@benchmark u1rows!($v, $(inds[1]), $(inds[2]), $(un[1]), $(un[3]), $(un[2]), $(un[4])))
    end
    println("unrows($ng)")
    display(@benchmark unrows!($v, $inds, $un))
    println("unrows-static($ng)")
    display(@benchmark unrows!($v, $sinds, $sun))
end


println("PERMUTETION")
for ng in [1,2]
    n=1<<ng
    v = randn(ComplexF64, 1<<16)
    un = pmrand(n)
    sun = un |> staticize
    inds =  randperm(n) .+18
    sinds = SVector{n}(inds)

    println("unrows($ng)")
    display(@benchmark unrows!($v, $inds, $un))
    println("unrows-static($ng)")
    display(@benchmark unrows!($v, $sinds, $sun))
end
