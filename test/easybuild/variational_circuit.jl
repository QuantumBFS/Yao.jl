using Test
using Yao.EasyBuild

@testset "pairs geometries" begin
    @test pair_ring(3) == [1=>2,2=>3,3=>1]
    ps = pair_square(2, 2; periodic=false)
    @test length(ps) == 4
    for item in [1=>2, 3=>4, 1=>3, 2=>4]
        @test item in ps
    end

    ps = pair_square(2, 2; periodic=true)
    @test length(ps) == 8
    for item in [1=>2, 3=>4, 2=>1, 4=>3, 1=>3, 2=>4, 3=>1, 4=>2]
        @test item in ps
    end
end

@testset "random circuit" begin
    c = rand_circuit(1)
    @test c isa ChainBlock
    @test length(c) == 5
    c = rand_circuit(9)
    @test c isa ChainBlock
    @test length(c) == 45
end

@testset "rotter, collect_blocks, num_gradient, opgrad" begin
    @test  merged_rotor(true, true) == Rx(0.0)
    @test  merged_rotor(false, false) == merged_rotor() == chain(Rz(0.0), Rx(0.0), Rz(0.0))
    @test  merged_rotor(false, true) == chain(Rz(0.0), Rx(0.0))
    @test  merged_rotor(true, false) == chain(Rx(0.0), Rz(0.0))
    @test collect_blocks(RotationGate, rotorset(:Merged, 5, true, false)) |> length == 10

    @test rotor(5, 2, true, true) isa ChainBlock
    @test rotor(5, 2, true, true) |> length == 1
    @test rotor(5, 2, true, true) |> nqubits == 5
    @test collect_blocks(PutBlock{<:Any, <:Any, <:RotationGate}, rotorset(:Split, 5, true, false)) |> length == 10
end

@testset "entangler" begin
    c = variational_circuit(5; entangler=(n,i,j)->put(n,(i,j)=>ConstGate.CZ))
    @test nparameters(c) == 50
    c = variational_circuit(5; entangler=(n,i,j)->put(n,(i,j)=>rot(ConstGate.CNOT, 0.0)))
    @test nparameters(c) == 65
    ps = randn(nparameters(c))
    dispatch!(c, ps)
    @test parameters(c) ≈ ps
end
