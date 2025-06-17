using Test, YaoBlocks, YaoArrayRegister
using YaoAPI

@testset "Yao/#186" begin
    @test getiparams(phase(0.1)) == 0.1
    @test getiparams(Val(2) * phase(0.1)) == ()
    @test_throws NotImplementedError setiparams!(rot(X, 0.5), :nothing)
    @test_throws NotImplementedError setiparams(rot(X, 0.5), :nothing)
end

@testset "block to matrix conversion" begin
    for each in [X, Y, Z, H]
        Matrix{ComplexF64}(each) == Matrix{ComplexF64}(mat(each))
    end
    @test eltype(mat(chain(X))) == ComplexF64
    @test eltype(mat(chain(X, Rx(0.5)))) == ComplexF64
end

@testset "apply lambda" begin
    r = rand_state(3)
    @test apply!(copy(r), put(1 => X)) ≈ apply!(copy(r), put(3, 1 => X))
    r2 = copy(r)
    @test apply(r, put(1 => X)) ≈ apply!(copy(r), put(3, 1 => X))
    @test r2.state == r.state
    f(x::Float32) = x
    @test_throws ErrorException apply!(r, f)
end

@testset "push tests" begin
    # copy return itself by default
    @test copy(X) === X

    # block type can be used as traits
    @test nqubits(X) == 1

    @test isunitary(XGate)
    @test isreflexive(XGate)
    @test ishermitian(XGate)
    @test setiparams(Rx(0.3), 0.5) == Rx(0.5)
    @test setiparams(+, Rx(0.3), 0.5) == Rx(0.8)
    @test YaoBlocks.parameters_range(chain(Z, shift(0.3), phase(0.2), Rx(0.5), time_evolve(X, 0.5), Ry(0.5))) == [(0.0, 2π), (0.0, 2π), (0.0, 2π), (-Inf, Inf), (0.0, 2π)]
end

@testset "indexing pxp" begin
    function proj(::Type{T}, configs::AbstractVector{<:DitStr{D,N}}) where {T,D,N}
        mask = zeros(T, D^N)
        for c in configs
            mask[Int(c)+1] = one(T)
        end
        return matblock(Diagonal(mask); tag="Projector")
    end
    display(mat(proj(ComplexF64, [bit"00"])))
    function pxp(neighbors, i::Int)
        n = length(neighbors)
        P = chain([put(n, (i,j)=>proj(ComplexF64, [bit"10", bit"01", bit"00"])) for j in neighbors[i]])
        P * put(n, i=>X) * P
    end
    h = sum([pxp([[2], [1,3], [2, 4], [3, 5], [4]], i) for i=1:5])
    @test length(h[:,bit"11000"]) == 2
    @test length(h[:,bit"10100"]) == 3
end

@testset "render params" begin
    # rotation gate
    params = [first(YaoBlocks.render_params(Rx(0.5), Val(:random))) for i=1:100]
    @test any(>(1), params)  # in range [0, 2π]
    @test all(x -> 0<=x<=2π, params)
    @test YaoBlocks.render_params(Rx(0.5), Val(:zero)) == (0.0,)

    # shift gate
    sg = shift(0.5)
    params = [first(YaoBlocks.render_params(sg, Val(:random))) for i=1:100]
    @test any(>(1), params)  # in range [0, 2π]
    @test all(x -> 0<=x<=2π, params)
    @test YaoBlocks.render_params(sg, Val(:zero)) == (0.0,)

    # phase gate
    pg = phase(0.5)
    params = [first(YaoBlocks.render_params(pg, Val(:random))) for i=1:100]
    @test any(>(1), params)  # in range [0, 2π]
    @test all(x -> 0<=x<=2π, params)
    @test YaoBlocks.render_params(pg, Val(:zero)) == (0.0,)

    # time evolve gate
    sg = time_evolve(X, 0.5)
    params = [first(YaoBlocks.render_params(sg, Val(:random))) for i=1:100]
    @test all(x -> 0<=x<=1, params)
    @test YaoBlocks.render_params(sg, Val(:zero)) == (0.0,)
end