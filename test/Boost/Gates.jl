using Test, Random, LinearAlgebra, SparseArrays

using Yao
using Yao.Blocks
using LuxurySparse
using Yao.Intrinsics
using Yao.Boost

Yao.:⊗(A, B) = kron(A, B)

@testset "gate utils" begin
    @test hilbertkron(4, [mat(X), mat(Y)], [3,2]) == IMatrix(2) ⊗ mat(X) ⊗ mat(Y) ⊗ IMatrix(2)
    @test general_controlled_gates(2, [mat(P1)], [1], [mat(X)], [2]) == mat(CNOT)
end

@testset "controlled gates" begin
    @test cxgate(ComplexF64, 2, [2], [1], 1) == [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0] == controlled_U1(2, Matrix(mat(X)), [2], [1], 1)
    @test cxgate(ComplexF64, 2, [2], [0], 1) == [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1] == controlled_U1(2, Matrix(mat(X)), [2], [0], 1)
    @test controlled_U1(3, mat(Z), [3], [1], 2) == czgate(ComplexF64, 3, [3], [1], 2)
    @test czgate(ComplexF64, 2, [1], [1], 2) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1] == controlled_U1(2, mat(Z), [2], [1], 1)
    @test general_controlled_gates(12, [mat(P1)], [7], [mat(Z)], [3]) == czgate(ComplexF64, 12, [7], [1], 3)
    @test cxgate(ComplexF64, 2, [2], [1], 1) == [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
    @test general_controlled_gates(12, [mat(P1)], [7], [mat(X)], [3]) == cxgate(ComplexF64, 12, [7], [1], 3)

    @test general_controlled_gates(3, [mat(P1)], [3], [mat(X)], [2]) == controlled_U1(3, mat(X), [3], [1], 2) == cxgate(ComplexF64, 3, [3], [1], 2)
    @test general_controlled_gates(3, [mat(P1)], [3], [mat(Y)], [2]) == controlled_U1(3, mat(Y), [3], [1], 2) == cygate(ComplexF64, 3, [3], [1], 2)
    @test general_controlled_gates(3, [mat(P1)], [3], [mat(Z)], [2]) == controlled_U1(3, mat(Z), [3], [1], 2) == czgate(ComplexF64, 3, [3], [1], 2)

    # NC
    @test general_controlled_gates(3, [mat(P1), mat(P0)], [3, 1], [mat(X)], [2]) == controlled_U1(3, mat(X), [3, 1], [1, 0], 2) == cxgate(ComplexF64, 3, [3, 1], [1, 0], 2)
    @test general_controlled_gates(3, [mat(P1), mat(P0)], [3, 1], [mat(Y)], [2]) == controlled_U1(3, mat(Y), [3, 1], [1, 0], 2) == cygate(ComplexF64, 3, [3, 1], [1, 0], 2)
    @test general_controlled_gates(3, [mat(P1), mat(P0)], [3, 1], [mat(Z)], [2]) == controlled_U1(3, mat(Z), [3, 1], [1, 0], 2) == czgate(ComplexF64, 3, [3, 1], [1, 0], 2)
end

@testset "single gate" begin
    @test zgate(ComplexF64, 4, [1,2,3]) == hilbertkron(4, [mat(Z), mat(Z), mat(Z)], [1,2,3])
end

@testset "basic gate" begin
    # check matrixes
    for (gate, MAT) in [
        (xgate, mat(X)),
        (ygate, mat(Y)),
        (zgate, mat(Z)),
        #(hgate, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        @test Matrix(gate(ComplexF64, 1, 1)) == MAT
        @test hilbertkron(4, [MAT, MAT, MAT], [3,2,1]) == gate(ComplexF64, 4, 1:3)
    end
    #@test toffoligate(3, 2, 3, 1) == TOFFOLI_MAT
end

#=
# psi0
# ['sx', 'sy', 'sz', 'rx(np.pi/6)', 'ry(np.pi/6)', 'rz(np.pi/6)', 'rot(np.pi/6, np.pi/3, np.pi/6)'] apply on 6
# above gates controled by c(4)
# above gates controled by c(2)nc(4)c(5)
psi = loadldm("psi-test.jl")
psi = psi[:, 1:2:end] + im * psi[:, 2:2:end]
psi0 = psi[1,:]
num_bit = 8
# make following test pass
gates = [xgate, ygate, zgate, rxgate(pi/6), rygate(pi/6), rzgate(pi/6), zxzrot(pi/6, pi/3, pi/6)]
for gate, psii in zip(gates, psi[2:8])
    @test $gate(num_bit, 6)*psi0 == psii
end
cgates = [g|>c for g in gates]
for gate, psii in zip(cgates, psi[9:15])
    @test $gate(num_bit, 6, 4)*psi0 == psii
end
cnccgates = [g|>c|>nc|>c for g in gates]
for gate, psii in zip(cnccgates, psi[16:22])
    @test $gate(num_bit, 6, 2,4,5)*psi0 == psii
end
=#
