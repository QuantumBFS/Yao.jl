using Test, YaoBase, YaoArrayRegister, YaoBlockTree

@testset "constructor" begin
    g = Roller(X, kron(X, Y), Z, Z)
    occupied_locs(g) == 1:5

    src = phase(0.1)
    g = rollrepeat(4, src)
    g.blocks[1].theta = 0.2
    @test src.theta == 0.1
    @test g.blocks[2].theta == 0.1
    blks = [X, Y, kron(3, 2=>Rx(0.3))]
    @test_throws AddressConflictError chsubblocks(g, blks)
    blks = [X, Y, kron(2, 2=>Rx(0.3))]
    subblocks(chsubblocks(g, blks)) == blks
end

@testset "copy" begin
    g = rollrepeat(4, phase(0.1))
    cg = copy(g)

    cg.blocks[1].theta = 1.0
    @test g.blocks[1].theta == 1.0
end

@testset "setindex" begin
    g = rollrepeat(5, phase(0.1))
    @test_throws MethodError g.blocks[1] = X
end

@testset "iteration" begin
    g = rollrepeat(5, phase(0.1))
    for each in g.blocks
        @test each.theta == 0.1
    end

    g = Roller(X, kron(X, Y), Z, Z)
    list = [X, kron(X, Y), Z, Z]
    for (src, tg) in zip(g.blocks, list)
        @test src == tg
    end

    for i in eachindex(g.blocks)
        @test g.blocks[i] == list[i]
    end
end

@testset "tile one block" begin
    g = rollrepeat(5, X)
    @test state(apply!(ArrayReg(bit"11111"), g)) == state(ArrayReg(bit"00000"))
    @test state(apply!(ArrayReg{3}(bit"11111"), g)) == state(ArrayReg{3}(bit"00000"))
end

@testset "roll multiple blocks" begin
    g = Roller((X, Y, Z, X, X))
    tg = kron(5, X, Y, Z, X, X)
    @test state(apply!(ArrayReg(bit"11111"), g)) == state(apply!(ArrayReg(bit"11111"), tg))
    @test state(apply!(ArrayReg{3}(bit"11111"), g)) == state(apply!(ArrayReg{3}(bit"11111"), tg))
end

@testset "matrix" begin
    g = roll(X, kron(Y, Z), X, X)
    tg = kron(X, Y, Z, X, X)
    @test mat(g) == mat(tg)
    @test linop2dense(r->apply!(ArrayReg(r), g) |> statevec, 5) == mat(tg)

    m = kron(Const.CNOT, Const.I2, Const.X, Const.I2)
    r = roll(5, I2, X, I2, CNOT)
    @test m == mat(r)
end
