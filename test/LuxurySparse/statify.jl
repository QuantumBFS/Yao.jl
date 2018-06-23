using Compat
using Compat.Test
using Compat.LinearAlgebra

using Yao
using Yao.LuxurySparse
import Yao.LuxurySparse: statify
using StaticArrays: SVector, SMatrix

srand(2)

using Compat.Test
@testset "statify" begin
    m = pmrand(Complex128, 4)
    sm = m |> statify
    @test sm.perm isa SVector
    @test sm.vals isa SVector
    @test sm.perm == m.perm
    @test sm.vals == m.vals

    m = sprand(Complex128, 4,4, 0.5)
    sm = m |> statify
    @test sm.colptr isa SVector
    @test sm.rowval isa SVector
    @test sm.nzval isa SVector
    @test sm.nzval == m.nzval
    @test sm.rowval == m.rowval
    @test sm.colptr == m.colptr

    m = Diagonal(randn(Complex128, 4))
    sm = m |> statify
    @test sm.diag isa SVector
    @test sm.diag == m.diag

    m = randn(Complex128, 4)
    sm = m |> statify
    @test sm isa SVector
    @test sm == m

    m = randn(Complex128, 4, 4)
    sm = m |> statify
    @test sm isa SMatrix
    @test sm == m
end

