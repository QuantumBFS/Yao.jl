using Test, YaoArrayRegister, BitBasis, LinearAlgebra
using YaoAPI
using Adapt

@testset "test ArrayReg constructors" begin
    @test ArrayReg(rand(4)) isa ArrayReg{2}
    @test_logs (:warn, "Input matrix element type is not `Complex`, got `Float64`") ArrayReg(
        rand(4, 4),
    )
    @test ArrayReg(rand(ComplexF64, 4)) isa ArrayReg{2}
    @test ArrayReg(arrayreg(bit"101")) == arrayreg(bit"101")

    st = rand(ComplexF64, 4, 8)
    @test state(adjoint(ArrayReg(st))) == adjoint(st)

    @test state(arrayreg(bit"101")) == reshape(onehot(bit"101"), :, 1)
    @test datatype(arrayreg(ComplexF32, bit"101")) == ComplexF32

    st = rand(ComplexF64, 4, 8)
    reg= ArrayReg{2}(st)
    @test similar(reg) isa ArrayReg
    @test nactive(similar(reg)) == 2
    m = randn(ComplexF64, 8, 8)
    @test similar(reg, m).state == m
    @test viewbatch(reg, 1) == reg
    @test_throws ErrorException viewbatch(reg, 2)
end

@testset "test BatchedArrayReg constructors" begin
    @test BatchedArrayReg(rand(4, 6), 3) isa BatchedArrayReg{2}
    @test_throws DimensionMismatch BatchedArrayReg(rand(4, 3), 2)
    @test_throws DimensionMismatch BatchedArrayReg(rand(5, 2), 2)
    @test BatchedArrayReg(rand(ComplexF64, 4, 3)) isa BatchedArrayReg{2}

    @test state(arrayreg(bit"101"; nbatch=2)) == repeat(reshape(onehot(bit"101"), :, 1), 1, 2)
    @test datatype(arrayreg(ComplexF32, bit"101"; nbatch=2)) == ComplexF32

    st = rand(ComplexF64, 4, 6)
    reg = BatchedArrayReg(st, 6)
    regt = transpose_storage(reg)
    @test regt.state isa Transpose
    @test regt == reg
    @test transpose_storage(regt).state isa Matrix
    @test transpose_storage(regt) == reg
    @test_throws ErrorException ArrayReg(reg)

    reg = zero_state(5; nbatch=1)
    @test reg isa BatchedArrayReg
    r2 = ArrayReg(reg)
    @test r2 isa ArrayReg
    @test BatchedArrayReg(r2) == reg

    st = rand(ComplexF64, 4, 8)
    reg= BatchedArrayReg{2}(st, 4)
    @test similar(reg) isa BatchedArrayReg
    @test nactive(similar(reg)) == 2
    @test nqubits(similar(reg)) == 3
    m = randn(ComplexF64, 8, 8)
    @test similar(reg, m).state == m
end

@testset "test $T initialization methods" for T in [ComplexF64, ComplexF32, ComplexF16]
    @testset "test product state" begin
        reg = product_state(T, bit"100")
        st = state(reg)
        @test nqudits(reg) == 3
        @test !(st isa Transpose)
        st2 = state(product_state(T, [0, 0, 1]))
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
        st = state(zero_state(T, 3))
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
        st = state(rand_state(T, 3))
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
        st = state(uniform_state(T, 3))
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
        r = repeat(arrayreg(T, bit"101"; nbatch=3), 4)
        @test nactive(r) == 3
        @test nbatch(r) == 12
    end
end

@testset "test YaoAPI interface" begin
    @testset "test probs" begin
        r = rand_state(5; nbatch = 3)
        @test probs(r) ≈ abs2.(state(r))
        r = rand_state(5)
        @test probs(r) ≈ abs2.(state(r))
    end
    @testset "test batch iteration" begin
        r = arrayreg(bit"101"; nbatch= 3)
        for k = 1:3
            @test viewbatch(r, k) == arrayreg(bit"101")
        end
        # broadcast
        for each in r
            @test each == arrayreg(bit"101")
        end
    end
    @testset "test append_qudits!" begin
        @test append_qudits!(zero_state(3), 3) == zero_state(6)
        r = rand_state(3; nbatch = 2)
        @test append_qudits!(copy(r), 2) ≈ join(zero_state(2; nbatch = 2), r)
        r = rand_state(3; nbatch = 1)
        @test append_qudits!(copy(r), 2) ≈ join(zero_state(2; nbatch = 1), r)
        @test copy(r) |> append_qubits!(2) ≈ join(zero_state(2; nbatch = 1), r)
    end
end

@testset "test statevec" begin
    r = arrayreg(bit"101"; nbatch=3)
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
    r = join(arrayreg(bit"011"), zero_state(1))
    focus!(r, 2:4)
    @test sum(r.state, dims = 2) ≈ arrayreg(bit"011").state
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
    reg = ArrayReg{3}(reshape(randn(ComplexF64, 9), :, 1))
    @test nlevel(reg) == 3
    @test nactive(reg) == 2
    @test_throws MethodError nqubits(reg)
    @test nqudits(reg) == 2

    # constructors
    reg = zero_state(2; nlevel=3)
    @test statevec(reg) == [1.0, 0.0im, 0, 0, 0, 0, 0, 0, 0]
    @test statevec(product_state(2, 1; nlevel=3)) == [0.0, 1.0+0.0im, 0, 0, 0, 0, 0, 0, 0]
    @test length(statevec(rand_state(2; nlevel=3))) == 9
    @test size(statevec(zero_state(2; nbatch=5, nlevel=3))) == (9,5)
end

@testset "more (push test coverage)" begin
    reg1 = transpose_storage(rand_state(3; nbatch=5))
    reg2 = transpose_storage(rand_state(3; nbatch=5))
    res = reg1' * reg2
    @test res ≈ (reg1') .* reg2

    reg = transpose_storage(focus!(rand_state(6), [2,3]))
    @test reg.state isa Transpose
    @test copy(reg).state isa Transpose
    
    copyto!(reg1', reg2')
    @test reg1 ≈ reg2
    @test reorder!(reg1, [2,3,1]).state ≈ reshape(permutedims(reshape(reg2.state, 2, 2, 2, 5), sortperm([2,3,1,4])), 8, 5)
end

@testset "most_probable" begin
    reg = arrayreg(ComplexF64[0.0, 0.6, 0.8, 0.0])
    reg2 = arrayreg(ComplexF64[0.0, 0.6, 0.0, 0.8])
    mp = most_probable(reg, 1)
    @test length(mp) == 1 && mp[1] === BitStr{2}(2)
    @test most_probable(reg, 2) == BitStr{2}.([2, 1])
    breg = BatchedArrayReg(reg, reg2)
    @test most_probable(breg, 2) == BitStr{2}.([2 3; 1 1])
end

@testset "mock register" begin
    # mocked registers
    struct TestRegister <: AbstractRegister{2} end

    YaoArrayRegister.nqudits(::TestRegister) = 8
    YaoArrayRegister.nactive(::TestRegister) = 2

    export TestInterfaceRegister
    struct TestInterfaceRegister <: AbstractRegister{2} end

    @testset "Test general interface" begin
        @test_throws MethodError nactive(TestInterfaceRegister())
        @test_throws MethodError nqubits(TestInterfaceRegister())
        @test_throws MethodError nremain(TestInterfaceRegister())
    end

    @testset "adjoint register" begin
        @test adjoint(TestRegister()) isa AdjointRegister
        @test adjoint(adjoint(TestRegister())) isa TestRegister
        @test nqubits(adjoint(TestRegister())) == 8
        @test nactive(adjoint(TestRegister())) == 2
    end
end
