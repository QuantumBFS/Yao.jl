using YaoBlocks, YaoArrayRegister, LinearAlgebra
using Test

@testset "check apply" begin
    r = rand_state(1)
    @test_throws ErrorException UnitaryChannel([X, Y, Z], [1, 0.2, 0])
    channel = UnitaryChannel([X, Y, Z], [1, 0, 0])
    print(channel)
    k1 = cache_key(channel)
    k2 = cache_key(chsubblocks(channel, [Z, Z, Z]))
    @test k1 != k2
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

@testset "kron and repeat" begin
    dm = density_matrix(ghz_state(5), 1:3)
    dpolarizing = single_qubit_depolarizing_channel(0.1)
    dmkron = apply(dm, kron(3, 1=>dpolarizing, 2=>dpolarizing))
    dmrepeat = apply(dm, repeat(3, dpolarizing, (1, 2)))
    dmput = apply(apply(dm, put(3, 1=>dpolarizing)), put(3, 2=>dpolarizing))
    @test dmkron ≈ dmrepeat
    @test dmkron ≈ dmput
end

@testset "kron" begin
    n_qubits = 3
    op1 = matblock(rand_unitary(2))
    op2 = matblock(rand_unitary(2))
    mixed_unitary_channel = MixedUnitaryChannel([op1, op2], [0.5, 0.5])
    mixed_unitary_channel2 = MixedUnitaryChannel([op1, op2], [0.5, 0.5])
    mixed_unitary_channel3 = kron(mixed_unitary_channel, mixed_unitary_channel2)

    circ1 = chain(n_qubits, put(n_qubits, 1 => mixed_unitary_channel), put(n_qubits, 2 => mixed_unitary_channel2))
    circ2 = chain(n_qubits, put(n_qubits, (1, 2) => mixed_unitary_channel3))

    reg = rand_state(n_qubits)
    @test noisy_simulation(reg, circ1) ≈ noisy_simulation(reg, circ2)
end

@testset "depolarizing channel - constructor" begin
    n_qubits = 2
    p = 0.1
    depolarizing = DepolarizingChannel(n_qubits, p)
    @test cache_key(depolarizing) isa UInt64
    @test depolarizing == copy(depolarizing)
    @test depolarizing' == depolarizing
    @test subblocks(depolarizing) == ()
    @test occupied_locs(depolarizing) == (1, 2)
end

@testset "depolarizing channel - representations" begin
    for n_qubits in [1, 3]
        p = 0.1
        depolarizing = DepolarizingChannel(n_qubits, p)
        mixed_unitary_channel = MixedUnitaryChannel(depolarizing)
        @test SuperOp(depolarizing) ≈ SuperOp(mixed_unitary_channel)

        # test apply
        r = rand_state(n_qubits)
        rho = density_matrix(r)
        r1 = apply(rho, depolarizing)
        r2 = apply(rho, mixed_unitary_channel)
        expected_state = (1-p) * rho.state + p/(2^n_qubits) * IMatrix(size(rho.state, 1))
        @test tr(expected_state) ≈ 1
        @test tr(r1.state) ≈ 1
        @test tr(r2.state) ≈ 1
        @test r1.state ≈ expected_state
        @test r2.state ≈ expected_state
    end
end