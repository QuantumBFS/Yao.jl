using YaoBlocks, YaoArrayRegister
using Test

@testset "check apply" begin
    r = rand_state(1)
    channel = UnitaryChannel([X, Y, Z], [1, 0, 0])
    @test apply!(copy(r), channel) == apply!(copy(r), X)

    r = rand_state(3)
    @test apply!(copy(r), put(3, 1 => channel)) == apply!(copy(r), put(3, 1 => X))
    @test_throws QubitMismatchError apply!(copy(r), channel)
end

@testset "check mat" begin
    @test mat(UnitaryChannel([X, Y, Z], [1, 0, 0])) == mat(X)
    @test mat(UnitaryChannel([X, Y, Z], [0, 1, 0])) == mat(Y)
    @test mat(UnitaryChannel([X, Y, Z], [0, 0, 1])) == mat(Z)
end

@testset "check compare" begin
    @test UnitaryChannel([X, Y, Z], [1, 0, 0]) == UnitaryChannel([X, Y, Z], [1, 0, 0])
    @test UnitaryChannel([X, Y, Z], [1, 0, 0]) != UnitaryChannel([X, Y, Z], [1, 1, 0])
    @test UnitaryChannel([X, Y, Z], [1, 0, 0]) != UnitaryChannel([X, Y], [1, 1, 0])
end

@testset "check adjoint" begin
    channel = UnitaryChannel([X, Y, Z])
    adj_channel = adjoint(channel)
    @test adjoint.(adj_channel.operators) == channel.operators
end

@testset "check ocuppied locations" begin
    channel = UnitaryChannel(put.(6, [1 => X, 3 => Y, 5 => Z]))
    @test occupied_locs(channel) == [1, 3, 5]
end
