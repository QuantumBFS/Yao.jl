using Test, YaoBlocks, YaoArrayRegister
using YaoBase

@testset "Yao/#186" begin
    @test getiparams(phase(0.1)) == 0.1
    @test getiparams(2 * phase(0.1)) == ()
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

# copy return itself by default
@test copy(X) === X

# block type can be used as traits
@test nqubits(typeof(X)) == 1
