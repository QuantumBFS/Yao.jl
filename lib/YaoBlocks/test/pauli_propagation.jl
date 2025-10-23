using YaoBlocks, PauliPropagation, YaoArrayRegister, Test
using Random

_isequal(a::GA, b::GB) where {GA<:Gate, GB<:Gate} =  all([getproperty(a, pn) == getproperty(b, pn) for pn in fieldnames(GA)])
_isequal(a::Vector{GA}, b::Vector{GB}) where {GA<:Gate, GB<:Gate} = all(_isequal.(a, b))

@testset "test PauliPropagationExt" begin
    nq = 3
    nl = 2
    circuit = tfitrottercircuit(nq, nl)
    yaocirc = YaoBlocks.paulipropagation2yao(nq, circuit, randn(countparameters(circuit)))
    obs = put(nq, 1=>Z)
    pc = YaoBlocks.yao2paulipropagation(yaocirc; observable=obs)
    @test pc.n == nq
    @test _isequal(getfield.(pc.gates, :gate), circuit)
    # Test that observable is a PauliSum
    @test pc.observable isa PauliSum
    # Test round-trip conversion
    yaocirc2 = paulipropagation2yao(pc)
    @test nqubits(yaocirc) == nqubits(yaocirc2)
end

@testset "expectation value" begin
    n_qubits = 8
    n_layers = 20
    error_rate = 0.01

    function build_noisy_layer(n::Int, error_rate::Float64)
        layer = chain(n)

        for i in 1:n
            if rand() < 0.5
                push!(layer, put(n, i => Rx(2π * rand())))
            else
                push!(layer, put(n, i => Rz(2π * rand())))
            end
        end

        for i in 1:2:n-1
            push!(layer, put(n, (i, i + 1) => YaoBlocks.ConstGate.CNOT))
        end

        for i in 1:n
            push!(layer, put(n, i => quantum_channel(DepolarizingError(1, error_rate))))
        end

        return layer
    end

    circuit = chain(n_qubits)
    for i in 1:n_qubits
        push!(circuit, put(n_qubits, i => H))
    end

    for layer_idx in 1:n_layers
        append!(circuit, build_noisy_layer(n_qubits, error_rate))
    end

    reg = zero_state(n_qubits) |> density_matrix
    reg_final = apply!(copy(reg), circuit)

    pauli_z_expectations = Float64[]
    yao_z_expectations = Float64[]
    for i in 1:min(10, n_qubits)
        pc = yao2paulipropagation(circuit; observable=put(n_qubits, i => Z))
        exp_pauli = real(overlapwithzero(propagate(pc)))
        push!(pauli_z_expectations, exp_pauli)
        exp_yao = real(expect(put(n_qubits, i => Z), reg_final))
        push!(yao_z_expectations, exp_yao)
    end

    @test pauli_z_expectations ≈ yao_z_expectations atol=1e-6
end

@testset "simulation" begin
    nq = 8
    pstr = PauliString(nq, :Z, 3)
    nl = 4
    topology = bricklayertopology(nq; periodic=false)

    circuit = hardwareefficientcircuit(nq, nl; topology=topology)
    nparams = countparameters(circuit)
    thetas = randn(nparams) * 0.5

    yao_circ = YaoBlocks.paulipropagation2yao(nq, circuit, thetas)
    psum_exact = propagate(circuit, pstr, thetas; min_abs_coeff=0)
    psum_yao = apply!(zero_state(nq), yao_circ)

    exact_expectation = overlapwithzero(psum_exact)
    yao_expectation = expect(put(nq, 3 => Z), psum_yao)
    @test isapprox(exact_expectation, yao_expectation, atol=1e-6)
end

# noisy simulation
@testset "pauli noisy simulation" begin
    Random.seed!(1234)
    nq = 3
    nl = 2
    W = Inf
    min_abs_coeff = 0.0
    opind = rand(1:nq)
    pstr = PauliString(nq, :Z, opind)

    topo = bricklayertopology(nq; periodic=false)
    circ = hardwareefficientcircuit(nq, nl; topology=topo)

    m = countparameters(circ)

    depolarizing_circ = deepcopy(circ)
    pauli_circ = deepcopy(circ)

    where_ind = rand(1:m)
    q_ind = opind
    noise_p = 0.1
    insert!(depolarizing_circ, where_ind, DepolarizingNoise(q_ind))
    insert!(pauli_circ, where_ind, PauliZNoise(q_ind))
    insert!(pauli_circ, where_ind, PauliYNoise(q_ind))
    insert!(pauli_circ, where_ind, PauliXNoise(q_ind))

    thetas1 = rand(m)
    thetas2 = deepcopy(thetas1)
    insert!(thetas1, where_ind, noise_p)
    pauli_p = 1 - sqrt(1 - noise_p)
    insert!(thetas2, where_ind, pauli_p)
    insert!(thetas2, where_ind, pauli_p)
    insert!(thetas2, where_ind, pauli_p)


    dnum1 = propagate(depolarizing_circ, pstr, thetas1; max_weight=W, min_abs_coeff=min_abs_coeff)
    dnum2 = propagate(pauli_circ, pstr, thetas2; max_weight=W, min_abs_coeff=min_abs_coeff)

    exp1 = overlapwithzero(dnum1)
    exp2 = overlapwithzero(dnum2)
    @test exp1 ≈ exp2

    # convert to Yao blocks
    yao_depolarizing_circ = YaoBlocks.paulipropagation2yao(nq, depolarizing_circ, thetas1)
    yao_pauli_circ = YaoBlocks.paulipropagation2yao(nq, pauli_circ, thetas2)
    exp_yao1 = expect(put(nq, opind => Z), zero_state(nq) |> density_matrix |> yao_depolarizing_circ)
    exp_yao2 = expect(put(nq, opind => Z), zero_state(nq) |> density_matrix |> yao_pauli_circ)

    @test exp1 ≈ exp_yao1
    @test exp2 ≈ exp_yao2

    # convert back
    pc1 = YaoBlocks.yao2paulipropagation(yao_depolarizing_circ; observable=put(nq, opind => Z))
    @test _isequal(pc1.gates, depolarizing_circ)
    @test isempty(pc1.thetas)  # since we freeze the parameters
    pc2 = YaoBlocks.yao2paulipropagation(yao_pauli_circ; observable=put(nq, opind => Z))
    @test _isequal(getfield.(pc2.gates, :gate), pauli_circ)
    @test isempty(pc2.thetas)  # since we freeze the parameters
end
