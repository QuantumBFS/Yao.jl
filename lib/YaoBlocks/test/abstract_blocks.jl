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