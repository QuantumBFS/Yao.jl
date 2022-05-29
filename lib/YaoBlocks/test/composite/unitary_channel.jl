using YaoBlocks, YaoArrayRegister
using Test

@testset "check apply" begin
    r = rand_state(1)
    @test_throws ErrorException UnitaryChannel([X, Y, Z], [1, 0.2, 0])
    channel = UnitaryChannel([X, Y, Z], [1, 0, 0])
    # broken because Unitary channel does not have a matrix representation
    @test_throws ErrorException apply!(copy(r), channel)
    @test apply!(density_matrix(r), channel) ≈ density_matrix(apply!(copy(r), X))

    r = rand_state(3)
    @test_throws QubitMismatchError apply!(copy(r), channel)
end

@testset "check mat" begin
    @test_throws ErrorException mat(UnitaryChannel([X, Y, Z], [1, 0, 0]))
end

@testset "check compare" begin
    @test UnitaryChannel([X, Y, Z], [1, 0, 0]) == UnitaryChannel([X, Y, Z], [1, 0, 0])
    @test_throws AssertionError UnitaryChannel([X, Y], [1, 1, 0])
end

@testset "check adjoint" begin
    channel = UnitaryChannel([X, Y, Z], [0.2, 0.8, 0.0])
    adj_channel = adjoint(channel)
    @test adjoint.(adj_channel.operators) == channel.operators
end

@testset "check ocuppied locations" begin
    channel = UnitaryChannel(put.(6, [1 => X, 3 => Y, 5 => Z]), [0.1, 0.2, 0.7])
    @test occupied_locs(channel) == [1, 3, 5]
end

@testset "density matrix" begin
    @test_throws ErrorException UnitaryChannel(put.(6, [1 => X, 3 => Y, 5 => Z]), [0.1, 0.3, 0.1])
    channel = UnitaryChannel(put.(6, [1 => X, 3 => Y, 5 => Z]), [0.1, 0.3, 0.6])
end
