using Compat.Test
include("basis.jl")

@testset "basis" begin
    # test pauli - vec transformation
    s = random_pauli()
    vec = s |> pauli2vec
    @test isapprox(vec |> s, s)

    # test polar - vec transformation
    vec = randn(3)
    polar = vec |> vec2polar
    @test isapprox(vec, polar |> polar2vec)

    polar = polar[2:end]
    u = polar |> polar2u
    @test isapprox(polar, u |> u2polar)
    @test isapprox(abs(conj(u))*u, 1)
end
