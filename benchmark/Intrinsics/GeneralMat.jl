using Yao
using Yao.Intrinsics
using LuxurySparse
using SparseArrays
using StaticArrays
using LinearAlgebra
using Yao.Blocks
using Test

using BenchmarkTools

println("##### Matrix #####")
nbit = 16
mmm = randn(ComplexF64, 2, 2)
println("u1mat, t ≈ 600us")
display(@benchmark u1mat(nbit, $mmm, 2))

println("\nunmat, t ≈ 1.1ms")
display(@benchmark unmat(nbit, $mmm, (2,)))
@test u1mat(nbit, mmm, 2) == unmat(nbit, mmm, (2,))

println("\n##### SparseMatrixCSC #####")
nbit = 16
mmm = mat(P1)
println("unmat, t ≈ 1.1ms")
display(@benchmark unmat(nbit, $mmm, (2,)))

println("\n######## PermMatrix #############")
nbit = 16
mmm = X |> mat
println("unmat, t ≈ 300us")
display(@benchmark unmat(nbit, $mmm, (2,)))

println("\n######## Diagonal #############")
nbit = 16
mmm = Z |> mat
println("unmat, t ≈ 400us")
display(@benchmark unmat(nbit, $mmm, (2,)))
