using Test, YaoArrayRegister, BitBasis, LinearAlgebra
using YaoBase
using Adapt

@testset "test constructors" begin
    @test ArrayReg{3}(rand(4, 6)) isa ArrayReg{3}
    @test_throws DimensionMismatch ArrayReg{2}(rand(4, 3))
    @test_throws DimensionMismatch ArrayReg{2}(rand(5, 2))
    @test_logs (:warn, "Input type of `ArrayReg` is not Complex, got Float64") ArrayReg(
        rand(4, 3),
    )

    @test ArrayReg(rand(ComplexF64, 4, 3)) isa ArrayReg{3}
    @test ArrayReg(rand(ComplexF64, 4)) isa ArrayReg{1}

    @test state(ArrayReg(bit"101")) == reshape(onehot(bit"101"), :, 1)
    @test datatype(ArrayReg(ComplexF32, bit"101")) == ComplexF32
    @test ArrayReg(ArrayReg(bit"101")) == ArrayReg(bit"101")

    st = rand(ComplexF64, 4, 6)
    @test state(adjoint(ArrayReg(st))) == adjoint(st)

    reg = ArrayReg{6}(st)
    regt = transpose_storage(reg)
    @test regt.state isa Transpose
    @test regt == reg
    @test transpose_storage(regt).state isa Matrix
    @test transpose_storage(regt) == reg
end

@testset "test $T initialization methods" for T in [ComplexF64, ComplexF32, ComplexF16]
    @testset "test product state" begin
        reg = product_state(T, bit"100"; nbatch = 1)
        st = state(reg)
        @test nqudits(reg) == 3
        @test !(st isa Transpose)
        st2 = state(product_state(T, [0, 0, 1]; nbatch = 1))
        @test st2 ≈ st
        st = state(product_state(T, bit"100"; nbatch = 2, no_transpose_storage = true))
        @test !(st isa Transpose)
        st = state(product_state(T, bit"100"; nbatch = 2))
        @test st isa Transpose
        for k = 1:2
            @test st[:, k] ≈ onehot(T, bit"100")
        end

        st = state(product_state(T, 4, 0; nbatch = 3))
        for k = 1:3
            @test st[:, k] ≈ onehot(T, 4, 0)
        end
        @test eltype(product_state(Float64, 4, 0).state) == Float64
    end
    @testset "test zero state" begin
        st = state(zero_state(T, 3; nbatch = 1))
        @test !(st isa Transpose)
        st = state(zero_state(T, 3; nbatch = 2, no_transpose_storage = true))
        @test !(st isa Transpose)
        st = state(zero_state(T, 4; nbatch = 4))
        @test st isa Transpose
        for k = 1:4
            @test st[:, k] ≈ onehot(T, 4, 0)
        end
        @test eltype(zero_state(Float64, 4).state) == Float64
    end
    @testset "test rand state" begin
        st = state(rand_state(T, 3; nbatch = 1))
        @test !(st isa Transpose)
        st = state(rand_state(T, 3; nbatch = 2, no_transpose_storage = true))
        @test !(st isa Transpose)
        # NOTE: we only check if the state is normalized
        st = state(rand_state(T, 4, nbatch = 2))
        @test st isa Transpose
        for k = 1:2
            @test norm(st[:, k]) ≈ 1.0
        end
        @test eltype(rand_state(Float64, 4).state) == Float64
    end
    @testset "test uniform state" begin
        st = state(uniform_state(T, 3; nbatch = 1))
        @test !(st isa Transpose)
        st = state(uniform_state(T, 3; nbatch = 2, no_transpose_storage = true))
        @test !(st isa Transpose)
        st = state(uniform_state(T, 4; nbatch = 2))
        @test st isa Transpose
        for k = 1:2
            for each in st[:, k]
                @test each ≈ 1 / sqrt(16)
            end
        end
        @test eltype(uniform_state(Float64, 4).state) == Float64
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
        r = rand_state(5; nbatch = 3)
        @test probs(r) ≈ abs2.(state(r))
        r = rand_state(5)
        @test probs(r) ≈ abs2.(state(r))
    end
    @testset "test batch iteration" begin
        r = ArrayReg{3}(bit"101")
        for k = 1:3
            @test viewbatch(r, k) == ArrayReg(bit"101")
        end
        # broadcast
        for each in r
            @test each == ArrayReg(bit"101")
        end
    end
    @testset "test addbits!" begin
        @test addbits!(zero_state(3), 3) == zero_state(6)
        r = rand_state(3; nbatch = 2)
        @test addbits!(copy(r), 2) ≈ join(zero_state(2; nbatch = 2), r)
        r = rand_state(3; nbatch = 1)
        @test addbits!(copy(r), 2) ≈ join(zero_state(2; nbatch = 1), r)
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
    @test r4 |> relaxedvec ≈
          focus!(copy(r3), [1, 2, 3, 7, 8, 4, 5, 6, 9, 10, 11, 12]) |> relaxedvec
    reg5 = focus!(repeat(r1, 3), 1:3)
    reg6 = focus!(repeat(r2, 3), 1:2)
    @test (join(reg6, reg5)|>relaxedvec)[:, 1] ≈ r4 |> relaxedvec

    # manual trace
    r = join(ArrayReg(bit"011"), zero_state(1))
    focus!(r, 2:4)
    @test sum(r.state, dims = 2) ≈ ArrayReg(bit"011").state
end

@testset "YaoBlocks.jl/issues/21" begin
    st = rand(ComplexF64, 16, 2)
    r1 = ArrayReg(view(st, :, 1))
    r2 = ArrayReg(rand(ComplexF64, 16, 1))
    copyto!(r1, r2)
    @test r1 == r2
end

@testset "transpose copy" begin
    reg = rand_state(5; nbatch = 10)
    reg1 = copy(reg)
    reg2 = focus!(copy(reg), (3, 5))
    reg3 = relax!(copy(reg2), (3, 5))
    reg4 = oneto(reg1, 3)
    @test reg1.state isa Transpose
    @test reg2.state isa Transpose
    @test reg3.state isa Transpose
    @test reg4.state isa Transpose
    @test reg4.state ≈ oneto(reg, 3).state
    reg4.state[1] = 2.0
    @test reg.state[1] != 2.0
end

@testset "collapseto" begin
    reg = rand_state(4)
    reg2 = copy(reg)
    focus!(reg, (4, 2))
    collapseto!(reg, bit"01")
    relax!(reg, (4, 2), to_nactive = 4)
    instruct!(reg2, Const.P0, (2,))
    instruct!(reg2, Const.P1, (4,))
    normalize!(reg2)
    @test reg ≈ reg2
end

@testset "overlap between two focused reg" begin
    rega = rand_state(5)
    regb = rand_state(5)
    reg1 = focus!(copy(rega), (3, 2, 4))
    reg2 = focus!(copy(regb), (3, 2, 4))
    @test reg1' * reg2 ≈ rega' * regb
end

@testset "adapt" begin
    @test datatype(adapt(Array{ComplexF32}, zero_state(5))) == ComplexF32
end

@testset "von_neumann_entropy" begin
    reg = (product_state(bit"00000") + product_state(bit"11111")) / sqrt(2)
    @test von_neumann_entropy(reg, [2,3]) ≈ log(2)
    @test mutual_information(reg, [2,3], [5]) ≈ log(2)
end

@testset "qudit" begin
    reg = ArrayReg{1,3}(reshape(randn(9), :, 1))
    @test nlevel(reg) == 3
    @test nactive(reg) == 2
    @test_throws MethodError nqubits(reg)
    @test nqudits(reg) == 2
end
