using Test, YaoToEinsum, YaoBlocks, YaoBlocks.BitBasis, YaoBlocks.YaoArrayRegister
using YaoToEinsum: pauli_basis_transformer, to_pauli_basis, to_pauli_basis_observable

@testset "map density matrix" begin
    circuit = chain(5, [put(5, i=>H) for i=1:5]..., [control(5, 1, i=>Z) for i=2:5]..., repeat(5, H))

    # first, we show the density matrix mode is just the abs2 of the vector mode
    initial_state = Dict([i => rand_state(1) for i=1:5])
    reg0 = join([initial_state[5-i+1] for i=1:5]...)
    final_state = Dict([i => rand_state(1) for i=1:5])
    reg1 = join([final_state[5-i+1] for i=1:5]...)
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, final_state=final_state)
    res1 = contract(network)[]
    res2 = abs2(reg1' * (copy(reg0) |> circuit))
    @test res1 ≈ res2

    # then, we check the density matrix input is correct
    network_dm = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=Dict([k=>density_matrix(v) for (k, v) in initial_state]), final_state=Dict([k=>density_matrix(v) for (k, v) in final_state]))
    res3 = contract(network_dm)[]
    @test res3 ≈ res1

    # then, we show the density matrix mode supports observables
    @test_throws AssertionError yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, final_state=final_state, observable=put(5, 1=>Z))
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, observable=put(5, 1=>X))
    res1 = contract(network)[]
    res2 = expect(put(5, 1=>X), copy(reg0) |> circuit)
    @test res1 ≈ res2

    # then, we check the superop
    network = yao2einsum(circuit, mode=DensityMatrixMode())
    res1 = reshape(contract(network), 2^10, 2^10)
    res2 = SuperOp(circuit).superop
    @test res1 ≈ res2

    # then, we check the channels
    c0 = quantum_channel(DepolarizingError(5, 0.1))     # DepolarizingChannel
    c1 = quantum_channel(DepolarizingError(1, 0.1))     # DepolarizingChannel
    c2 = quantum_channel(PauliError(0.1, 0.2, 0.3))  # MixedUnitaryChannel
    c3 = quantum_channel(ResetError(0.1, 0.0))            # KrausChannel
    c4 = KrausChannel([matblock(randn(ComplexF64, 4, 4)) for _=1:2])            # KrausChannel
    circuit = chain(5, [put(5, i=>H) for i=1:5]..., c0, put(5, 1=>c1), put(5, 2=>c2), put(5, 3=>c3), put(5, (4, 5)=>c4), [control(5, 1, i=>Z) for i=2:5]..., repeat(5, H))
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, observable=put(5, 1=>Z))
    res1 = contract(network)[]
    res2 = expect(put(5, 1=>Z), density_matrix(reg0) |> circuit)
    @test res1 ≈ res2 atol=1e-8
end

@testset "pauli basis" begin
    n = 2
    U = pauli_basis_transformer(ComplexF64, n)
    rho = DensityMatrix{2}(randn(ComplexF64, 2^n, 2^n))
    op = SuperOp(randn(ComplexF64, 4^n, 4^n))
    op2 = put(n, 1=>X)
    rho1 = apply(to_pauli_basis(rho), to_pauli_basis(op))
    rho2 = apply(rho, op)
    res1 = sum(vec(rho1.state) .* vec(to_pauli_basis_observable(mat(op2))))
    res2 = sum(vec(rho2.state) .* vec(mat(op2)))
    @test res1 ≈ res2
end

@testset "pauli basis mode" begin
    circuit = chain(5, [put(5, i=>H) for i=1:5]..., [control(5, 1, i=>Z) for i=2:5]..., repeat(5, H))
    initial_state = Dict([i => rand_state(1) for i=1:5])
    reg0 = join([initial_state[5-i+1] for i=1:5]...)
    final_state = Dict([i => rand_state(1) for i=1:5])
    reg1 = join([final_state[5-i+1] for i=1:5]...)
    network0 = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, final_state=final_state)
    network = yao2einsum(circuit, mode=PauliBasisMode(), initial_state=initial_state, final_state=final_state)
    res1 = contract(network)[]
    res0 = contract(network0)[]
    obs = kron(5, [i=>matblock(final_state[i].state * final_state[i].state') for i=1:5]...)
    @test mat(obs) ≈ density_matrix(reg1).state atol=1e-8
    res2 = expect(obs, density_matrix(reg0) |> circuit)
    @show res0 res1 res2
    @test res0 ≈ res2
    @test res1 ≈ res2
end