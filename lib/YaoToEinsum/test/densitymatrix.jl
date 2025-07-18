using Test, YaoToEinsum, YaoBlocks, YaoBlocks.BitBasis, YaoBlocks.YaoArrayRegister

@testset "map density matrix" begin
    circuit = chain(5, [put(5, i=>H) for i=1:5]..., [control(5, 1, i=>Z) for i=2:5]..., repeat(5, H))

    # first, we show the density matrix mode is just the abs2 of the vector mode
    initial_state = Dict([i => rand_state(1) for i=1:5])
    reg0 = join([initial_state[5-i+1] for i=1:5]...)
    final_state = Dict([i => 1 for i=1:5])
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, final_state=final_state)
    res1 = contract(network)[]
    res2 = abs2(product_state(bit"11111")' * (copy(reg0) |> circuit))
    @test res1 ≈ res2

    # then, we show the density matrix mode supports observables
    @test_throws AssertionError yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, final_state=final_state, observable=put(5, 1=>Z))
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, observable=put(5, 1=>Z))
    res1 = contract(network)[]
    res2 = expect(put(5, 1=>Z), copy(reg0) |> circuit)
    @test res1 ≈ res2

    # then, we check the channels
    c1 = quantum_channel(DepolarizingError(1, 0.1))     # DepolarizingChannel
    c2 = quantum_channel(PauliError(0.1, 0.2, 0.3))  # MixedUnitaryChannel
    c3 = quantum_channel(ResetError(0.1, 0.0))            # KrausChannel
    c4 = KrausChannel([matblock(randn(ComplexF64, 4, 4)) for _=1:2])            # KrausChannel
    circuit = chain(5, [put(5, i=>H) for i=1:5]..., put(5, 1=>c1), put(5, 2=>c2), put(5, 3=>c3), put(5, (4, 5)=>c4), [control(5, 1, i=>Z) for i=2:5]..., repeat(5, H))
    network = yao2einsum(circuit, mode=DensityMatrixMode(), initial_state=initial_state, observable=put(5, 1=>Z))
    res1 = contract(network)[]
    res2 = expect(put(5, 1=>Z), density_matrix(reg0) |> circuit)
    @test res1 ≈ res2 atol=1e-8
end