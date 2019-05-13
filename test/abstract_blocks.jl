using Test, YaoBlocks, YaoArrayRegister

@testset "Yao/#186" begin
    @test getiparams(phase(0.1)) == 0.1
    @test getiparams(2 * phase(0.1)) == ()
end

@testset "block to matrix conversion" begin
    for each in [X, Y, Z, H]
        Matrix{ComplexF64}(each) == Matrix{ComplexF64}(mat(each))
    end
end

@testset "apply lambda" begin
    r = rand_state(3)
    @test apply!(copy(r), put(1=>X)) ≈ apply!(copy(r), put(3, 1=>X))
    f(x::Float32) = x
    @test_throws ErrorException apply!(r, f)
end

# copy return itself by default
@test copy(X) === X

# block type can be used as traits
@test nqubits(typeof(X)) == 1
