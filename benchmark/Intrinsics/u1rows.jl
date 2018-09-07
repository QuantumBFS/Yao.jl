using LuxurySparse

using Yao
using Yao.Intrinsics
using Random
using BenchmarkTools
using Statistics
using LinearAlgebra
using SparseArrays

vreg = randn(ComplexF64, 1<<16)
mreg = randn(ComplexF64, 1<<16, 2)

randmat(::Type{Val{:Dense}}, n) = randn(ComplexF64,n,n)
randmat(::Type{Val{:Diag}}, n) = Diagonal(randn(ComplexF64,n))
randmat(::Type{Val{:Perm}}, n) = pmrand(ComplexF64, n)
randmat(::Type{Val{:CSC}}, n) = SparseMatrixCSC(pmrand(ComplexF64, n))

vs = [vreg, mreg]

for m in [:Diag, :Dense, :Perm, :Diag]
    for v in [1,2]
        token = "$m * $(v ==1 ? "Vec" : "Mat")"
        for ng in [1,2]
            n=1<<ng
            un = randmat(Val{m}, n)
            sun = un |> staticize
            inds =  randperm(n) .+18
            sinds = SVector{n}(inds)

            if ng==1 && m == :Dense
                println("$token, u1rows($ng) => ", median(@benchmark u1rows!($(vs[v]), $(inds[1]), $(inds[2]), $(un[1]), $(un[3]), $(un[2]), $(un[4]))))
            end
            #println("$token, dynamic($ng) => ", median(@benchmark unrows!($(vs[v]), $inds, $un) seconds=1))
            res = @benchmark unrows!($(vs[v]), $sinds, $sun)
            println("$token, static($ng) => ", median(res))
            display(res)
        end
    end
end


using StaticArrays: SVector, SMatrix, SDiagonal

@inline function unrows!(state::Vector, inds::AbstractVector, A::Union{SSparseMatrixCSC, SparseMatrixCSC}, work::Vector)
    work .= 0
    @inbounds for col = 1:length(inds)
        xj = state[inds[col]]
        @inbounds @simd for j = A.colptr[col]:(A.colptr[col + 1] - 1)
            work[A.rowval[j]] += A.nzval[j]*xj
        end
    end
    state[inds] = work
    state
end

n=2
inds =  randperm(n) .+18
sinds = SVector{n}(inds)
un = Diagonal(randn(ComplexF64, n))
#un = randmat(Val{:CSC}, n)
sun = un |> staticize;

work = Vector{ComplexF64}(undef, n)
#@benchmark unrows!($vreg, $sinds, $sun, $work)
@benchmark unrows!($mreg, $sinds, $sun)
