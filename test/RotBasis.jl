using Test, Random, LinearAlgebra, SparseArrays

using Yao
using QuAlgorithmZoo

@testset "RotBasis" begin
    rt = RotBasis(0.5, 0.4)
    crt = chain(rt)

    dispatch!(crt, [2., 3.])
    @test nparameters(crt) == 2

    for (t1, t2, t3) in zip(parameters(rt), (2, 3), parameters(crt))
        @test t1 == t2 == t3
    end

    # check consistency
    rb = put(1, 1=>RotBasis(0.1, 0.3))#rot_basis(1)
    angles = randpolar(1)
    # prepair a state in the angles direction.
    psi = angles |> polar2u |> ArrayReg

    # rotate to the same direction for measurements.
    dispatch!(rb, vec(angles))
    @test state(apply!(psi, rb)) ≈ [1, 0]

    @test nparameters(rot_basis(3)) == 6
    dispatch!(rb, :zero)
    @test parameters(rb)[1] == 0
    dispatch!(rb, :random)
    @test parameters(rb)[1] != 0
end

@testset "polar and u" begin
    polar = randpolar(10)
    @test size(polar) == (2, 10)
    @test polar |> polar2u |> u2polar ≈ polar
end
