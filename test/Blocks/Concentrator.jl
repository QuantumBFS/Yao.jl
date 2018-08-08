using Test, Random, LinearAlgebra, SparseArrays

using Yao
# type
using Yao.Blocks

@testset "concentrator" begin
    reg = rand_state(10)
    block = kron(4, 2=>X)
    c = Concentrator{10}(block, [1,3,9,2]);

    @test nqubits(c) == 10
    @test nactive(c) == 4
    @test isunitary(c) == true
    @test isreflexive(c) == true
    @test ishermitian(c) == true

    @test apply!(copy(reg), c) == apply!(copy(reg), kron(10, 3=>X))
end
