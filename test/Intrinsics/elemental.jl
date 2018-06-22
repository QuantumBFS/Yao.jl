using Compat
using Compat.Test
using StaticArrays: SMatrix, SVector
import Yao.Intrinsics: swaprows!, mulrow!, notdense, swapcols!, mulcol!, u1rows!, unrows!

@testset "swaprows! & mulrow!" begin
    a = [1,2,3,5.0]
    A = Float64.(reshape(1:8, 4,2))
    @test swaprows!(copy(a), 2, 4) ≈ [1,5,3,2]
    @test swaprows!(copy(a), 2, 4, 0.1, 0.2) ≈ [1,1,3,0.2]
    @test swapcols!(copy(a), 2, 4) ≈ [1,5,3,2]
    @test swapcols!(copy(a), 2, 4, 0.1, 0.2) ≈ [1,1,3,0.2]
    @test swaprows!(copy(A), 2, 4) ≈ [1 5; 4 8; 3 7; 2 6]
    @test swaprows!(copy(A), 2, 4, 0.1, 0.2) ≈ [1 5; 0.8 1.6; 3 7; 0.2 0.6]
    @test swapcols!(copy(A), 2, 1) ≈ [5 1; 6 2; 7 3; 8 4]
    @test swapcols!(copy(A), 2, 1, 0.1, 0.2) ≈ [0.5 0.2; 0.6 0.4; 0.7 0.6; 0.8 0.8]

    @test mulrow!(copy(a), 2, 0.1) ≈ [1,0.2,3,5]
    @test mulcol!(copy(a), 2, 0.1) ≈ [1,0.2,3,5]
    @test mulrow!(copy(A), 2, 0.1) ≈ [1 5; 0.2 0.6; 3 7; 4 8]
    @test mulcol!(copy(A), 2, 0.1) ≈ [1 0.5; 2 0.6; 3 0.7; 4 0.8]
end

@testset "u1rows! & unrows!" begin
    v = randn(ComplexF64, 1<<6)
    u1 = randn(ComplexF64, 2,2)
    su1 = SMatrix{2,2}(u1)
    inds1 =  [1,3]
    sinds1 = SVector{2}(inds1)
    @test u1rows!(copy(v), inds1..., u1[1], u1[3], u1[2], u1[4]) ≈ unrows!(copy(v), inds1, u1) ≈ unrows!(copy(v), sinds1, u1)
end
