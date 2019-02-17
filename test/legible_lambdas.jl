using Test, YaoBase

@testset "Legible Lambdas" begin
    f = @λ(x -> x + 1)
    @test f isa Function
    @test repr(f) == "(x->x + 1)"
    @test f(2) == 3

    g = @λ((x,y) -> x^2 + y^2)
    @test g isa Function
    @test repr(g) == "((x, y)->x ^ 2 + y ^ 2)"
    @test g(-15.0, 10.0) == 325.0

    h = @λ((x,y, z) -> occursin(x, y*z))
    @test h isa Function
    @test repr(h) == "((x, y, z)->occursin(x, y * z))"
    @test h("hi", "abh", "ing")

    D(f, ϵ=1e-10) = @λ(x -> (f(x+ϵ)-f(x))/ϵ)
    @test repr(D(sin)) == "(x->(f(x + ϵ) - f(x)) / ϵ)"
    @test D(sin)(π) == -1.000000082740371
end
