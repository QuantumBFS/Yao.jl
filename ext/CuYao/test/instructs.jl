using LinearAlgebra, Yao.ConstGate
using Test, Random
using Yao
using Yao.YaoArrayRegister.StaticArrays
using Yao.ConstGate: SWAPGate
using CUDA

@testset "gpu instruct nbit!" begin
    Random.seed!(3)
    nbit = 6
    N = 1<<nbit
    LOC1 = SVector{2}([0, 1])
    v1 = randn(ComplexF32, N)
    vn = randn(ComplexF32, N, 333)

    for UN in [
            rand_unitary(ComplexF32, 4),
            mat(ComplexF32, CNOT),
            mat(ComplexF32, control(2,2,1=>Z)),
            mat(ComplexF32, put(2,2=>I2)),
            mat(ComplexF32, put(2,2=>P0))
            ]
        @info "Testing $UN"
        @test instruct!(Val(2),v1 |> CuArray, UN, (3,1)) |> Vector ≈ instruct!(Val(2),v1 |> copy, UN, (3,1))
        @test instruct!(Val(2),vn |> CuArray, UN, (3,1)) |> Matrix ≈ instruct!(Val(2),vn |> copy, UN, (3,1))
    end
    # sparse matrix like P0, P1 et. al. are not implemented.
    for g in [mat(ComplexF32, ConstGate.T), mat(ComplexF32, ConstGate.H), mat(ComplexF32, rot(Z, 0.5))]
        @info "Testing $g"
        @test instruct!(Val(2), v1 |> CuArray, g, (3,), (4,), (1,)) |> Vector ≈ instruct!(Val(2), v1 |> copy, g, (3,), (4,), (1,))
        @test instruct!(Val(2), vn |> CuArray, g, (3,), (4,), (1,)) |> Matrix ≈ instruct!(Val(2), vn |> copy, g, (3,), (4,), (1,))
        @test instruct!(Val(2), v1 |> CuArray, g, (3,), (4,), (1,)) |> Vector ≈ instruct!(Val(2), v1 |> copy, g, (3,), (4,), (1,))
        @test instruct!(Val(2), vn |> CuArray, g, (3,), (4,), (1,)) |> Matrix ≈ instruct!(Val(2), vn |> copy, g, (3,), (4,), (1,))
    end
end

@testset "gpu swapapply!" begin
    nbit = 6
    N = 1<<nbit
    LOC1 = SVector{2}([0, 1])
    v1 = randn(ComplexF32, N)
    vn = randn(ComplexF32, N, 333)

    @test instruct!(Val(2),v1 |> CuArray, Val(:SWAP), (3,5)) |> Vector ≈ instruct!(Val(2),v1 |> copy, Val(:SWAP), (3,5))
    @test instruct!(Val(2),vn |> CuArray, Val(:SWAP), (3,5)) |> Matrix ≈ instruct!(Val(2),vn |> copy, Val(:SWAP), (3,5))
end

@testset "gpu instruct! 1bit" begin
    nbit = 6
    N = 1<<nbit
    LOC1 = SVector{2}([0, 1])
    v1 = randn(ComplexF64, N)
    vn = randn(ComplexF64, N, 333)

    for U1 in [mat(H), mat(Z), mat(I2), mat(ConstGate.P0), mat(X), mat(Y)]
        @test instruct!(Val(2),v1 |> CuArray, U1, (3,)) |> Vector ≈ instruct!(Val(2),v1 |> copy, U1, (3,))
        @test instruct!(Val(2),vn |> CuArray, U1, (3,)) |> Matrix ≈ instruct!(Val(2),vn |> copy, U1, (3,))
    end
    # sparse matrix like P0, P1 et. al. are not implemented.
end

@testset "gpu xyz-instruct!" begin
    nbit = 6
    N = 1<<nbit
    LOC1 = SVector{2}([0, 1])
    v1 = randn(ComplexF32, N)
    vn = randn(ComplexF32, N, 333)

    for G in [:X, :Y, :Z, :T, :H, :Tdag, :S, :Sdag]
        @info "Testing $G"
        @test instruct!(Val(2),v1 |> CuArray, Val(G), (3,)) |> Vector ≈ instruct!(Val(2),v1 |> copy, Val(G), (3,))
        @test instruct!(Val(2),vn |> CuArray, Val(G), (3,)) |> Matrix ≈ instruct!(Val(2),vn |> copy, Val(G), (3,))
        if G != :H
            @test instruct!(Val(2),v1 |> CuArray, Val(G), (1,3,4)) |> Vector ≈ instruct!(Val(2),v1 |> copy, Val(G), (1,3,4))
            @test instruct!(Val(2),vn |> CuArray,  Val(G),(1,3,4)) |> Matrix ≈ instruct!(Val(2),vn |> copy, Val(G), (1,3,4))
        end
    end
end

@testset "gpu cn-xyz-instruct!" begin
    nbit = 6
    N = 1<<nbit
    LOC1 = SVector{2}([0, 1])
    v1 = randn(ComplexF32, N)
    vn = randn(ComplexF32, N, 333)

    for G in [:X, :Y, :Z, :T, :Tdag, :S, :Sdag]
        @info "Testing $G"
        @test instruct!(Val(2),v1 |> CuArray, Val(G), (3,), (4,5), (0, 1)) |> Vector ≈ instruct!(Val(2),v1 |> copy, Val(G), (3,), (4,5), (0, 1))
        @test instruct!(Val(2),vn |> CuArray, Val(G), (3,), (4,5), (0, 1)) |> Matrix ≈ instruct!(Val(2),vn |> copy, Val(G), (3,), (4,5), (0, 1))
        @test instruct!(Val(2),v1 |> CuArray, Val(G), (3,), (1,), (1,)) |> Vector ≈ instruct!(Val(2),v1 |> copy, Val(G),(3,), (1,), (1,))
        @test instruct!(Val(2),vn |> CuArray, Val(G), (3,), (1,), (1,)) |> Matrix ≈ instruct!(Val(2),vn |> copy, Val(G),(3,), (1,), (1,))
    end
end

@testset "pswap" begin
    ps = put(6, (2,4)=>rot(SWAP, π/2))
    reg = rand_state(6; nbatch=10)
    @test apply!(reg |> cu, ps) |> cpu ≈ apply!(copy(reg), ps)
    @test apply!(reg |> cu, ps).state isa CuArray
end

@testset "regression test: Rx, Ry, Rz, CPHASE" begin
    Random.seed!(3)
    nbit = 6
    for ps in [put(6, (2,)=>Rx(π/2)), put(6, 2=>Ry(0.5)),  put(6, 2=>Rz(0.4))]
        reg = rand_state(6; nbatch=10)
        @test apply!(reg |> cu, ps) |> cpu ≈ apply!(copy(reg), ps)
        @test apply!(reg |> cu, ps).state isa CuArray
    end
end

@testset "density matrix" begin
    nbit = 6
    reg = rand_state(nbit)
    rho = density_matrix(reg)
    c = put(6, (2,)=>Rx(π/3))
    @test apply(rho |> cu, c) |> cpu ≈ apply(rho, c)
end

@testset "time evolve" begin
    g = time_evolve(kron(10, 2=>X, 3=>X), 0.5)
    reg = rand_state(10)
    @test apply!(copy(reg), g) ≈ apply!(reg |> cu, g) |> cpu
end

# fix: https://github.com/QuantumBFS/CuYao.jl/issues/81
@testset "generic sparse (pqc circuit)" begin
    # kron of Rx
    pqc_circuit = subroutine(10, kron(Rx(0.4), Rx(0.5), Rx(0.6), Rx(0.8)), (1, 2, 6, 5))
    proxy_reg = zero_state(10)
    @test apply!(proxy_reg |> cu, pqc_circuit) |> cpu ≈ apply(proxy_reg, pqc_circuit)

    # kron of Rz
    pqc_circuit = subroutine(10, kron(Rz(0.4), Rz(0.5), Rz(0.6), Rz(0.8)), (1, 2, 6, 5))
    proxy_reg = zero_state(10)
    @test apply!(proxy_reg |> cu, pqc_circuit) |> cpu ≈ apply(proxy_reg, pqc_circuit)
end
