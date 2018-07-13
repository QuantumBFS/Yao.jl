using Compat.Test
using Yao
using Yao.Intrinsics
using Yao.Blocks
using Yao.Boost

@testset "XYZ" begin
    reg1 = rand_state(3)
    reg2 = rand_state(3, 2)
    for G in [X, Y, Z]
        rb = RepeatedBlock{3}(G, (1,2))
        res = kron(kron(mat(I2), mat(G)), mat(G))
        @test mat(rb) ≈ res
        @test apply!(copy(reg1), rb) |> statevec ≈ res*statevec(reg1)
        @test apply!(copy(reg2), rb) |> statevec ≈ res*statevec(reg2)

        rb = RepeatedBlock{3}(G, (1,))
        res = kron(kron(mat(I2), mat(I2)), mat(G))
        @test mat(rb) ≈ res
        @test apply!(copy(reg1), rb) |> statevec ≈ res*statevec(reg1)
        @test apply!(copy(reg2), rb) |> statevec ≈ res*statevec(reg2)
    end
end

@testset "U1" begin
    reg1 = rand_state(3)
    reg2 = rand_state(3, 2)
    for G in [H, rot(X, 0.5), rot(Z, 0.5), I2]
        rb = RepeatedBlock{3}(G, (1,))
        res = kron(kron(mat(I2), mat(I2)), mat(G))
        @test mat(rb) ≈ res
        @test apply!(copy(reg1), rb) |> statevec ≈ res*statevec(reg1)
        @test apply!(copy(reg2), rb) |> statevec ≈ res*statevec(reg2)
    end
end

@testset "Put" begin
    reg1 = rand_state(5)
    reg2 = rand_state(5, 2)
    for G in [H, rot(X, 0.5), rot(Z, 0.5), I2, X, Y, Z]
        rb = put(5, (5,3)=>control(2, (1,), 2=>G))
        res = mat(control(5, (5,), 3=>G))
        @test applymatrix(rb) ≈ res
        @test applymatrix(put(5, 3=>G)) ≈ mat(put(5, 3=>G))
    end
    b1 = put(5, (5,3,1)=>control(3, (-1, 3), 2=>rot(X, 0.3)))
    b2 = control(5, (-5, 1), 3=>rot(X, 0.3))
    @test applymatrix(b1) == mat(b2)
    @test apply!(copy(reg1), b1) == apply!(copy(reg1), b2)
end

@testset "Un Repeat" begin
    reg1 = rand_state(5)
    reg2 = rand_state(5, 2)
    G = MatrixBlock(kron(2, H, H))
    @test_throws AddressConflictError repeat(4, G, (1,2))
    rb = repeat(5, G, (1,4))
    rb2 = repeat(5, H, (1,2,4,5))
    MAT = reduce(kron, [mat(H), mat(H), mat(I2), mat(H), mat(H)])
    @test applymatrix(rb) ≈ MAT
    @test applymatrix(rb2) ≈ MAT
    @test mat(rb) ≈ MAT
    @test mat(rb2) ≈ MAT
end

