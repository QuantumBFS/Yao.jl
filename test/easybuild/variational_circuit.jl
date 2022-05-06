using Test
using Yao.EasyBuild
using Yao.EasyBuild: pair_ring, pair_square, merged_rotor, rotor, rotorset

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

@testset "rotter, collect_blocks, num_gradient, opgrad" begin
    @test  merged_rotor(Float64, true, true) == Rx(0.0)
    @test  merged_rotor(Float64, false, false) == merged_rotor(Float64) == chain(Rz(0.0), Rx(0.0), Rz(0.0))
    @test  merged_rotor(Float64, false, true) == chain(Rz(0.0), Rx(0.0))
    @test  merged_rotor(Float64, true, false) == chain(Rx(0.0), Rz(0.0))
    @test collect_blocks(RotationGate, rotorset(Float64, :Merged, 5, true, false)) |> length == 10

    @test rotor(Float64, 5, 2, true, true) isa ChainBlock
    @test rotor(Float64, 5, 2, true, true) |> length == 1
    @test rotor(Float64, 5, 2, true, true) |> nqubits == 5
    @test collect_blocks(PutBlock{2, <:Any, <:RotationGate}, rotorset(Float64, :Split, 5, true, false)) |> length == 10
end

@testset "entangler" begin
    c = variational_circuit(5, 5)
    @test nparameters(c) == 80
    c = variational_circuit(5; entangler=(n,i,j)->put(n,(i,j)=>ConstGate.CZ))
    @test nparameters(c) == 50
    c = variational_circuit(5; entangler=(n,i,j)->put(n,(i,j)=>rot(ConstGate.CNOT, 0.0)))
    @test nparameters(c) == 65
    ps = randn(nparameters(c))
    dispatch!(c, ps)
    @test parameters(c) ≈ ps
end
