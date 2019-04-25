using Test, YaoArrayRegister, BitBasis, LinearAlgebra

@testset "test constructors" begin
    @test ArrayReg{3}(rand(4, 6)) isa ArrayReg{3}
    @test_throws DimensionMismatch ArrayReg{2}(rand(4, 3))
    @test_throws DimensionMismatch ArrayReg{2}(rand(5, 2))
    @test_logs (:warn, "Input type of `ArrayReg` is not Complex, got Float64") ArrayReg(rand(4, 3))

    @test ArrayReg(rand(ComplexF64, 4, 3)) isa ArrayReg{3}
    @test ArrayReg(rand(ComplexF64, 4)) isa ArrayReg{1}

    @test state(ArrayReg(bit"101")) == reshape(onehot(bit"101"), :, 1)
    @test datatype(ArrayReg(ComplexF32, bit"101")) == ComplexF32
    @test ArrayReg(ArrayReg(bit"101")) == ArrayReg(bit"101")

    st = rand(ComplexF64, 4, 6)
    @test state(adjoint(ArrayReg(st))) == adjoint(st)
end

@testset "test $T initialization methods" for T in [ComplexF64, ComplexF32, ComplexF16]
    @testset "test product state" begin
        st = state(product_state(T, bit"100"; nbatch=2))
        for k in 1:2
            @test st[:, k] ≈ onehot(T, bit"100")
        end

        st = state(product_state(T, 4, 0; nbatch=3))
        for k in 1:3
            @test st[:, k] ≈ onehot(T, 4, 0)
        end
    end
    @testset "test zero state" begin
        st = state(zero_state(T, 4; nbatch=4))
        for k in 1:4
            @test st[:, k] ≈ onehot(T, 4, 0)
        end
    end
    @testset "test rand state" begin
        # NOTE: we only check if the state is normalized
        st = state(rand_state(T, 4, nbatch=2))
        for k in 1:2
            @test norm(st[:, k]) ≈ 1.0
        end
    end
    @testset "test uniform state" begin
        st = state(uniform_state(T, 4; nbatch=2))
        for k in 1:2
            for each in st[:, k]
                @test each ≈ 1/sqrt(16)
            end
        end
    end
    @testset "test oneto" begin
        r1 = uniform_state(ComplexF64, 4)
        r2 = oneto(r1, 2)
        @test nactive(r2) == 2
        @test r1 |> oneto(2) |> nactive == 2
    end
    @testset "test repeat" begin
        r = repeat(ArrayReg{3}(T, bit"101"), 4)
        @test nactive(r) == 3
        @test nbatch(r) == 12
    end
end

@testset "test YaoBase interface" begin
    @testset "test probs" begin
        r = rand_state(5; nbatch=3)
        @test probs(r) ≈ abs2.(state(r))
        r = rand_state(5)
        @test probs(r) ≈ abs2.(state(r))
    end
    @testset "test batch iteration" begin
        r = ArrayReg{3}(bit"101")
        for k in 1:3
            @test viewbatch(r, k) == ArrayReg(bit"101")
        end
        # broadcast
        for each in r
            @test each == ArrayReg(bit"101")
        end
    end
    @testset "test addbits!" begin
        @test addbits!(zero_state(3), 3) == zero_state(6)
        r = rand_state(3; nbatch=2)
        @test addbits!(copy(r), 2) ≈ join(zero_state(2; nbatch=2), r)
        r = rand_state(3; nbatch=1)
        @test addbits!(copy(r), 2) ≈ join(zero_state(2; nbatch=1), r)
    end
end

@testset "test statevec" begin
    r = ArrayReg{3}(bit"101")
    @test statevec(r) == r.state
    r = oneto(r, 2)
    @test statevec(r) == reshape(state(r), 4, 6)
end

@testset "test hypercubic" begin
    @test hypercubic(rand_state(3)) |> size == (2, 2, 2, 1)
end

# TODO: test concat multiple registers
@testset "test join" begin
    r1 = rand_state(6)
    r2 = rand_state(6)
    r3 = join(r2, r1)
    r4 = join(focus!(copy(r2), 1:2), focus!(copy(r1), 1:3))
    @test r4 |> relaxedvec ≈ focus!(copy(r3), [1,2,3,7,8,4,5,6,9,10,11,12]) |> relaxedvec
    reg5 = focus!(repeat(r1, 3), 1:3)
    reg6 = focus!(repeat(r2, 3), 1:2)
    @test (join(reg6, reg5) |> relaxedvec)[:,1] ≈ r4 |> relaxedvec

    # manual trace
    r = join(ArrayReg(bit"011"), zero_state(1))
    focus!(r, 2:4)
    @test sum(r.state, dims=2) ≈ ArrayReg(bit"011").state
end

@testset "YaoBlocks.jl/issues/21" begin
    st = rand(ComplexF64, 16, 2)
    r1 = ArrayReg(view(st, :, 1))
    r2 = ArrayReg(rand(ComplexF64, 16, 1))
    copyto!(r1, r2)
    @test r1 == r2
end
