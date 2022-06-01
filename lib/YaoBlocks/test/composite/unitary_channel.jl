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
    ops = put.(6, [1 => chain(Rx(0.4), Ry(0.5), Rz(0.4)), 3 => Y, 5 => Z])
    channel = UnitaryChannel(ops, [0.3, 0.1, 0.6])
    r = density_matrix(rand_state(12), (3,2,1,5,6,9))
    ms = mat.(ops)
    @test apply(r, channel).state ≈ channel.probs[1] * ms[1] * r.state * ms[1]' + channel.probs[2] * ms[2] * r.state * ms[2]' + channel.probs[3] * ms[3] * r.state * ms[3]'

    channel1 = unitary_channel([put(6, 2=>chain(Rx(0.4), Ry(0.5), Rz(0.4))), put(6, 3=>Y), put(6, 2=>Z)], [0.3, 0.1, 0.6])
    ops = unitary_channel([put(2, 1=>chain(Rx(0.4), Ry(0.5), Rz(0.4))), put(2,2=>Y), put(2,1=>Z)], [0.3, 0.1, 0.6])
    channel2 = put(6, (2,3)=>ops)
    @test apply(r, channel1) ≈ apply(r, channel2)
end