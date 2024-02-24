using Test
using Yao
const CuYao = Base.get_extension(Yao, :CuYao)
using LinearAlgebra
using Yao.YaoArrayRegister.BitBasis
using Statistics: mean
using Yao.YaoArrayRegister.StaticArrays
using CUDA
using Yao.YaoArrayRegister: batched_kron, batched_kron!, batch_normalize!
CUDA.allowscalar(false)

@testset "basics" begin
    a = randn(ComplexF64, 50, 20)
    ca = a|>cu
    batch_normalize!(ca)
    batch_normalize!(a)
    @test ca |> Matrix ≈ a

    for l = 1:100
        i, j = CuYao.tri2ij(l)
        @test (i-1)*(i-2)÷2+j == l
    end
end

@testset "constructor an measure" begin
    reg = rand_state(10)
    greg = reg |> cu
    @test greg isa CuYao.AbstractCuArrayReg
    @test eltype(greg.state) == ComplexF64
    myvec(x) = Vector(x)
    myvec(x::Number) = [x]
    for reg in [rand_state(10, nbatch=333), rand_state(10)]
        greg = reg |> cu
        @test size(measure(greg |> copy, nshots=10)) == size(measure(reg, nshots=10))
        @test size(measure!(greg |> copy)) == size(measure!(reg |> copy))
        @test size(measure!(ResetTo(0), greg |> copy)) == size(measure!(ResetTo(0), reg |> copy))
        @test size(measure!(RemoveMeasured(), greg |> copy)) == size(measure!(RemoveMeasured(), reg |> copy))
        @test select(greg |> copy, 12) |> cpu ≈ select(reg, 12)
        @test size(measure!(greg |> copy |> focus!(3,4,1))) == size(measure!(reg |> copy |> focus!(3,4,1)))
        @test greg |> copy |> focus!(3,4,1) |> relax!(3,4,1) |> cpu ≈ reg

        if nbatch(greg) == 1
            greg1 = greg |> copy |> focus!(1,4,3)
            greg0 = copy(greg1)
            res = measure!(RemoveMeasured(), greg1)
            @test select(greg0, res |> myvec) |> normalize! |> cpu ≈ greg1 |> cpu
        end

        greg1 = greg |> copy |> focus!(1,4,3)
        greg0 = copy(greg1)
        res = measure!(ResetTo(3), greg1)
        @test all(measure(greg1, nshots=10) .== 3)
        @test greg1 |> isnormalized
        @test all(select.(BatchedArrayReg(greg0 |> cpu), res |> myvec) .|> normalize! .≈ select.(BatchedArrayReg(greg1 |> cpu), 3))

        greg1 = greg |> copy |> focus!(1,4,3)
        greg0 = copy(greg1)
        res = measure!(greg1)
        @test all(select.(BatchedArrayReg(greg0 |> cpu), res |> myvec) .|> normalize! .≈ select.(BatchedArrayReg(greg1 |> cpu), res|>myvec))
    end

    @test join(rand_state(3) |> cu, rand_state(3) |> cu) |> nactive == 6
    @test join(rand_state(3, nbatch=10) |> cu, rand_state(3, nbatch=10) |> cu) |> nactive == 6
end

@testset "insert_qubits!" begin
    reg = rand_state(5; nbatch=10)
    res = insert_qudits!(reg |> cu, 3, 2) |> cpu
    @test insert_qudits!(reg, 3, 2) ≈ res
    @test append_qudits!(copy(reg) |> cu, 3) |> cpu ≈ append_qudits!(copy(reg), 3)

    reg = rand_state(5, nbatch=10) |>focus!(2,3)
    res = insert_qudits!(reg |> cu, 3, 2) |> cpu
    @test insert_qudits!(reg, 3, 2) ≈ res

    @test append_qudits!(copy(reg) |> cu, 3) |> cpu ≈ append_qudits!(copy(reg), 3)
end

@testset "cuda-op-measures" begin
    reg = rand_state(8; nbatch=32) |> cu
    op = repeat(5, X, 1:5)

    # measure!
    reg2 = reg |> copy
    res = measure!(op, reg2, 2:6)
    res2 = measure!(op, reg2, 2:6)
    @test size(res) == (32,)
    @test res2 == res

    reg = clone(ArrayReg([1,-1+0im]/sqrt(2.0)), 10) |> cu
    @test measure!(X, reg) |> mean ≈ -1
    reg = clone(ArrayReg([1.0,0+0im]), 1000)
    @test abs(measure!(X, reg) |> mean) < 0.1
end

@testset "cuda kron getindex" begin
    a = randn(3,4)
    b = randn(4,2)
    c = zeros(12,8)
    ca, cb, cc = cu(a), cu(b), cu(c)
    @test kron(ca, cb) |> Array ≈ kron(a, b)
    @test Yao.YaoArrayRegister.kron!(cc, ca, cb) |> Array ≈ kron(a,b)

    Yao.YaoArrayRegister.kron!(c,a,b)
    @test cc |> Array ≈ c

    v = randn(100) |> cu
    inds = [3,5,2,1,7,1]
    @test v[inds] ≈ v[inds |> CuVector]
end

@testset "cuda batched_kron" begin
    a = randn(3,4,5)
    b = randn(4,2,5)
    c = zeros(12,8,5)
    ca, cb, cc = cu(a), cu(b), cu(c)

    @test batched_kron(ca, cb) |> Array ≈ batched_kron(a, b)
    @test batched_kron!(cc, ca, cb) |> Array ≈ batched_kron(a, b)

    batched_kron!(c, a, b)
    @test cc |> Array ≈ c
end

@testset "zero_state, et al" begin
    for b = [4, NoBatch()]
        reg = cuzero_state(3; nbatch=b)
        @test cpu(reg) ≈ zero_state(3; nbatch=b) && reg isa CuYao.AbstractCuArrayReg
        reg = curand_state(3; nbatch=b)
        @test reg isa CuYao.AbstractCuArrayReg
        reg = cuuniform_state(3; nbatch=b)
        @test cpu(reg) ≈ uniform_state(3; nbatch=b) && reg isa CuYao.AbstractCuArrayReg
        reg = cuproduct_state(bit"110"; nbatch=b)
        @test cpu(reg) ≈ product_state(bit"110"; nbatch=b) && reg isa CuYao.AbstractCuArrayReg
        reg = cughz_state(3; nbatch=b)
        @test cpu(reg) ≈ ghz_state(3; nbatch=b) && reg isa CuYao.AbstractCuArrayReg
    end
end

