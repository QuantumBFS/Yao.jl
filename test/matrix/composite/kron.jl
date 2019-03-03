using Revise, Test, YaoBase, YaoBlockTree

@testset "test constructors" begin
    @test_throws AddressConflictError KronBlock{5}(4=>CNOT, 5=>X)
end

@testset "test mat" begin
    GateSet = [
        X, Y, Z,
        phase(0.1), phase(0.2), phase(0.3),
        rot(X, 0.1), rot(Y, 0.4), rot(Z, 0.2)
    ]

    U = Const.X
    U2 = Const.CNOT

    @testset "case 1" begin
        m = kron(Const.I2, U)
        g = KronBlock{2}(1=>X)
        @test m == mat(g)

        m = kron(U, Const.I2)
        g = KronBlock{2}(2=>X)
        @test m == mat(g)
        @test collect(occupied_locations(g)) == [2]
        blks = [Rx(0.3)]
        @test chsubblocks(g, blks) |> subblocks == blks

        m = kron(U2, Const.I2, U, Const.I2)
        g = KronBlock{5}(4=>CNOT, 2=>X)
        @test m == mat(g)
        @test g.addrs == [2, 4]
        @test collect(occupied_locations(g)) == [2, 4, 5]
    end
end

GateSet = [
    X, Y, Z,
    phase(0.1), phase(0.2), phase(0.3),
    rot(X, 0.1), rot(Y, 0.4), rot(Z, 0.2)]

U = Const.X
U2 = Const.CNOT

m = kron(Const.I2, U)
g = KronBlock{2}(1=>X)
@test m == mat(g)

m = kron(U, Const.I2)
g = KronBlock{2}(2=>X)
@test m == mat(g)
@test collect(occupied_locations(g)) == [2]
blks = [Rx(0.3)]
@test chsubblocks(g, blks) |> subblocks == blks

chsubblocks(g, blks)

m = kron(U2, Const.I2, U, Const.I2)
g = KronBlock{5}(4=>CNOT, 2=>X)
@test m == mat(g)
@test g.addrs == [2, 4]
@test collect(occupied_locations(g)) == [2, 4, 5]
