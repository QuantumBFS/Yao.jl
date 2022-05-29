using Test, YaoAPI, YaoArrayRegister, LinearAlgebra, LuxurySparse, SparseArrays
#using YaoArrayRegister.Const
using YaoArrayRegister: linop2dense, general_controlled_gates, parametric_mat

# NOTE: we don't have block here, feel safe to use

@testset "test general unitary instruction" begin
    U1 = randn(ComplexF64, 2, 2)
    ST = randn(ComplexF64, 1 << 4)
    REG = ArrayReg(ST)
    I2 = IMatrix(2)
    M = kron(I2, U1, I2, I2) * ST

    @test instruct!(Val(2), copy(ST), U1, (3,)) ≈ M ≈ instruct!(Val(2), reshape(copy(ST), :, 1), U1, (3,))

    U2 = rand(ComplexF64, 4, 4)
    M = kron(I2, U2, I2) * ST
    @test instruct!(Val(2), copy(ST), U2, (2, 3)) ≈ M

    @test instruct!(Val(2), copy(ST), kron(U1, U1), (3, 1)) ≈
          instruct!(Val(2), instruct!(Val(2), copy(ST), U1, (3,)), U1, (1,))
    @test instruct!(copy(REG), kron(U1, U1), (3, 1)) ≈
          instruct!(instruct!(copy(REG), U1, (3,)), U1, (1,))
    @test instruct!(transpose_storage(REG), kron(U1, U1), (3, 1)) ≈
          instruct!(instruct!(copy(REG), U1, (3,)), U1, (1,))
    @test instruct!(transpose_storage(REG), kron(U1, U1), (3, 1)) ≈
          instruct!(instruct!(transpose_storage(REG), U1, (3,)), U1, (1,))

    @test instruct!(Val(2), reshape(copy(ST), :, 1), kron(U1, U1), (3, 1)) ≈
          instruct!(Val(2), instruct!(Val(2), reshape(copy(ST), :, 1), U1, (3,)), U1, (1,))

    U2 = sprand(ComplexF64, 8, 8, 0.1)
    ST = randn(ComplexF64, 1 << 5)
    M = kron(I2, U2, I2) * ST
    @test instruct!(Val(2), copy(ST), U2, (2, 3, 4)) ≈ M

    @test instruct!(Val(2), copy(ST), I2, (1,)) ≈ ST
    @test instruct!(Val(2), copy(ST), IMatrix(4), (2,3)) ≈ ST

    STB = randn(ComplexF64, 2 ^ 4, 5)
    U1 = randn(ComplexF64, 2, 2)
    REGB = BatchedArrayReg(STB, 5)
    @test instruct!(copy(REGB), U1, (3,)).state ≈ instruct!(Val(2), copy(STB), U1, (3,)) ≈ instruct!(Val(2), copy(STB), U1, (3,), (), ())
    @test instruct!(arrayreg(copy(STB); nbatch=5), randn(ComplexF64, 2, 2), ()) |> state ≈ STB

    # PermMatrix
    U1 = PermMatrix([0.0 -1.0im; 1.0im 0.0im])
    @test instruct!(copy(REGB), U1, (3,)).state ≈ instruct!(copy(REGB), Val(:Y), (3,)).state
    @test instruct!(copy(REGB), Diagonal([1.0, im]), (3,)).state ≈ instruct!(copy(REGB), Val(:S), (3,)).state
end

@testset "test auto conversion" begin
    v = rand(ComplexF32, 1 << 8)
    if VERSION < v"1.6-"
        @test_logs (
            :warn,
            "Element Type Mismatch: register Complex{Float32}, operator Complex{Float64}. Converting operator to match, this may cause performance issue",
        ) instruct!(arrayreg(v), Const.CNOT, (1, 2))
    else
        @test_logs (
            :warn,
            "Element Type Mismatch: register ComplexF32, operator ComplexF64. Converting operator to match, this may cause performance issue",
        ) instruct!(arrayreg(v), Const.CNOT, (1, 2))
    end
end


@testset "test general control unitary operator" begin
    ST = randn(ComplexF64, 1 << 5)
    U1 = randn(ComplexF64, 2, 2)
    instruct!(Val(2), copy(ST), U1, (3,), (1,), (1,))

    @test instruct!(Val(2), copy(ST), U1, (3,), (1,), (1,)) ≈
          general_controlled_gates(5, [Const.P1], [1], [U1], [3]) * ST
    @test instruct!(Val(2), copy(ST), U1, (3,), (1,), (0,)) ≈
          general_controlled_gates(5, [Const.P0], [1], [U1], [3]) * ST

    # control U2
    U2 = kron(U1, U1)
    @test instruct!(Val(2), copy(ST), U2, (3, 4), (1,), (1,)) ≈
          general_controlled_gates(5, [Const.P1], [1], [U2], [3]) * ST

    # multi-control U2
    @test instruct!(Val(2), copy(ST), U2, (3, 4), (5, 1), (1, 0)) ≈
          general_controlled_gates(5, [Const.P1, Const.P0], [5, 1], [U2], [3]) * ST
end


@testset "test Pauli instructions" begin
    @testset "test $G instructions" for (G, M) in zip((:X, :Y, :Z), (Const.X, Const.Y, Const.Z))
        @test linop2dense(s -> instruct!(Val(2), s, Val(G), (1,)), 1) == M
        @test linop2dense(s -> instruct!(Val(2), s, Val(G), (1, 2, 3)), 3) == kron(M, M, M)
    end

    @testset "test controlled $G instructions" for (G, M) in zip((:X, :Y, :Z), (Const.X, Const.Y, Const.Z))
        @test linop2dense(s -> instruct!(Val(2), s, Val(G), (4,), (2, 1), (0, 1)), 4) ≈
              general_controlled_gates(4, [Const.P0, Const.P1], [2, 1], [M], [4])

        @test linop2dense(s -> instruct!(Val(2), s, Val(G), (1,), (2,), (0,)), 2) ≈
              general_controlled_gates(2, [Const.P0], [2], [M], [1])
    end
end

@testset "single qubit instruction" begin
    ST = randn(ComplexF64, 1 << 4)
    Pm = pmrand(ComplexF64, 2)
    Dv = Diagonal(randn(ComplexF64, 2))

    @test instruct!(Val(2), copy(ST), Pm, (3,)) ≈
          kron(Const.I2, Pm, Const.I2, Const.I2) * ST ≈
          instruct!(Val(2), reshape(copy(ST), :, 1), Pm, (3,))
    @test instruct!(Val(2), copy(ST), Dv, (3,)) ≈
          kron(Const.I2, Dv, Const.I2, Const.I2) * ST ≈
          instruct!(Val(2), reshape(copy(ST), :, 1), Dv, (3,))
end

@testset "swap instruction" begin
    ST = randn(ComplexF64, 1 << 2)
    @test instruct!(Val(2), copy(ST), Val(:SWAP), (1, 2)) ≈ Const.SWAP * ST
end

@testset "pswap instruction" begin
    ST = randn(ComplexF64, 1 << 2)
    θ = π / 3
    @test instruct!(Val(2), copy(ST), Val(:PSWAP), (1, 2), θ) ≈
          (cos(θ / 2) * IMatrix{4}() - im * sin(θ / 2) * Const.SWAP) * ST

    T = ComplexF64
    theta = 0.5
    for (R, G) in [(:Rx, Const.X), (:Ry, Const.Y), (:Rz, Const.Z), (:PSWAP, Const.SWAP)]
        @test parametric_mat(T, Val(R), theta) ≈ rot_mat(T, G, theta)
    end
    @test parametric_mat(T, Val(:CPHASE), theta) ≈
          rot_mat(T, Diagonal([1, 1, 1, -1]), theta) * exp(im * theta / 2)
    for ST in [randn(ComplexF64, 1 << 5), randn(ComplexF64, 1 << 5, 10)]
        @test instruct!(Val(2), copy(ST), Val(:H), (4,)) ≈ instruct!(Val(2), copy(ST), Const.H, (4,))
        for R in [:Rx, :Ry, :Rz]
            @test instruct!(Val(2), copy(ST), Val(R), (4,), θ) ≈
                  instruct!(Val(2), copy(ST), Matrix(parametric_mat(T, Val(R), θ)), (4,))
            @test instruct!(Val(2), copy(ST), Val(R), (4,), (1,), (0,), θ) ≈
                  instruct!(Val(2), copy(ST), Matrix(parametric_mat(T, Val(R), θ)), (4,), (1,), (0,))
        end
        for R in [:CPHASE, :PSWAP]
            @test instruct!(Val(2), copy(ST), Val(R), (4, 2), θ) ≈
                  instruct!(Val(2), copy(ST), Matrix(parametric_mat(T, Val(R), θ)), (4, 2))
            instruct!(Val(2), copy(ST), Val(R), (4, 2), (1,), (0,), θ)
            instruct!(Val(2), copy(ST), Matrix(parametric_mat(T, Val(R), θ)), (4, 2), (1,), (0,))
            @test instruct!(Val(2), copy(ST), Val(R), (4, 2), (1,), (0,), θ) ≈
                  instruct!(Val(2), copy(ST), Matrix(parametric_mat(T, Val(R), θ)), (4, 2), (1,), (0,))
        end
    end
end

@testset "Yao.jl/#189" begin
    st = rand(1 << 4)
    @test instruct!(Val(2), st, IMatrix{2,Float64}(), (1,)) == st
end

@testset "test empty locs" begin
    st = rand(ComplexF64, 1 << 4)
    pm = pmrand(ComplexF64, 2)
    @test instruct!(arrayreg(copy(st)), pm, ()) |> statevec == st

    for G in [:Z, :S, :T, :Sdag, :Tdag]
        @test instruct!(arrayreg(copy(st)), Val(G), ()) |> statevec == st
    end
end

@testset "register insterface" begin
    r = rand_state(5)
    @test instruct!(copy(r), Val(:X), (2,)).state ≈ instruct!(Val(2), copy(r.state), Val(:X), (2,))
    @test instruct!(copy(r), Val(:X), (2,), (3,), (1,)).state ≈
          instruct!(Val(2), copy(r.state), Val(:X), (2,), (3,), (1,))
    @test instruct!(copy(r), Val(:Rx), (2,), 0.5).state ≈
          instruct!(Val(2), copy(r.state), Val(:Rx), (2,), 0.5)
    @test instruct!(copy(r), Val(:Rx), (2,), (3,), (1,), 0.5).state ≈
          instruct!(Val(2), copy(r.state), Val(:Rx), (2,), (3,), (1,), 0.5)
end


@testset "regression test, rot CNOT - please run with multi-threading" begin
    g = [
        0.921061-0.389418im 0.0+0.0im 0.0+0.0im 0.0+0.0im
        0.0+0.0im 0.921061-0.0im 0.0+0.0im 0.0-0.389418im
        0.0+0.0im 0.0+0.0im 0.921061-0.389418im 0.0+0.0im
        0.0+0.0im 0.0-0.389418im 0.0+0.0im 0.921061-0.0im
    ]
    n = 16
    gs = sparse(g)
    reg1 = rand_state(n)
    reg2 = copy(reg1)
    for i = 1:50
        x1 = rand(1:n)
        x2 = rand(1:n-1)
        x2 = x2 >= x1 ? x2 + 1 : x2
        instruct!(reg1, g, (x1, x2))
        instruct!(reg2, gs, (x1, x2))
    end
    @test isapprox(norm(statevec(reg1)), 1.0; atol = 1e-5)
    @test isapprox(norm(statevec(reg2)), 1.0; atol = 1e-5)
    @test isapprox(statevec(reg1), statevec(reg2))
end

@testset "push coverage" begin
    state = randn(ComplexF64, 3^5)
    # identity fallback
    @test instruct!(Val(3), copy(state), IMatrix{3,ComplexF64}(), (1,)) == state
    U = randn(ComplexF64,3,3)
    # error on control
    @test_throws ErrorException instruct!(Val(3), state, U, (1,), (2,), (4,))
    @test instruct!(Val(3), copy(state), U, (1,), (), ()) ≈ instruct!(Val(3), copy(state), U, (1,))
    U2 = randn(ComplexF64,9,9)
    @test instruct!(Val(3), copy(state), U2, (3,1), (), ()) ≈ instruct!(Val(3), copy(state), U2, (3,1))
end

@testset "density matrix instruct" begin
    for G in [pmrand(ComplexF64,4), Diagonal(randn(ComplexF64,4)), sprand(ComplexF64,4,4,0.5), IMatrix{4}()]
        reg = rand_state(8)
        reg1 = instruct!(copy(reg), G, (4,2), (1,), (0,))
        r = density_matrix(reg)
        instruct!(r, G, (4,2), (1,), (0,))
        @test r ≈ density_matrix(reg1)
    end
    for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag, :H]
        reg = rand_state(8)
        reg1 = instruct!(copy(reg), Val(G), (4,))
        r = density_matrix(reg)
        instruct!(r, Val(G), (4,))
        @test r ≈ density_matrix(reg1)
    end
    for G in [:SWAP]
        reg = rand_state(8)
        reg1 = instruct!(copy(reg), Val(G), (4,2))
        r = density_matrix(reg)
        instruct!(r, Val(G), (4,2))
        @test r ≈ density_matrix(reg1)
    end
    for G in [:CPHASE, :PSWAP]
        reg = rand_state(8)
        reg1 = instruct!(copy(reg), Val(G), (4,2), 0.5)
        r = density_matrix(reg)
        instruct!(r, Val(G), (4,2), 0.5)
        @test r ≈ density_matrix(reg1)
    end
    for G in [:Rx, :Ry, :Rz]
        reg = rand_state(8)
        reg1 = instruct!(copy(reg), Val(G), (4,), 0.5)
        r = density_matrix(reg)
        instruct!(r, Val(G), (4,), 0.5)
        @test r ≈ density_matrix(reg1)
    end
end