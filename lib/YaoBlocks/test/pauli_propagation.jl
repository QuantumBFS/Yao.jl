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
    println(pc)
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
    @test _isequal(getfield.(pc1.gates, :gate), depolarizing_circ)
    pc2 = YaoBlocks.yao2paulipropagation(yao_pauli_circ; observable=put(nq, opind => Z))
    @test _isequal(getfield.(pc2.gates, :gate), pauli_circ)
end

@testset "observable types" begin
    n = 5
    circ = chain(n, put(n, 1=>X), put(n, 2=>Rx(0.5)))
    
    # Test PutBlock with different Pauli gates
    for (pauli_gate, pauli_sym) in [(X, :X), (Y, :Y), (Z, :Z)]
        obs = put(n, 1=>pauli_gate)
        pc = yao2paulipropagation(circ; observable=obs)
        @test pc.observable isa PauliSum
        @test length(pc.observable) == 1
    end
    
    # Test KronBlock (multi-qubit Pauli product)
    obs_kron = kron(n, 1=>X, 2=>Z, 3=>Y)
    pc_kron = yao2paulipropagation(circ; observable=obs_kron)
    @test pc_kron.observable isa PauliSum
    @test length(pc_kron.observable) == 1
    psum_kron = propagate(pc_kron)
    @test psum_kron isa PauliSum
    
    # Test Scale (scaled observable)
    obs_scale = 2.5 * put(n, 2=>Y)
    pc_scale = yao2paulipropagation(circ; observable=obs_scale)
    @test pc_scale.observable isa PauliSum
    @test length(pc_scale.observable) == 1
    # Check coefficient (access via terms dict)
    coeffs = collect(values(pc_scale.observable.terms))
    @test abs(coeffs[1]) ≈ 2.5
    
    # Test Scale with KronBlock
    obs_scale_kron = 3.0 * kron(n, 1=>X, 2=>Z)
    pc_scale_kron = yao2paulipropagation(circ; observable=obs_scale_kron)
    @test pc_scale_kron.observable isa PauliSum
    coeffs_kron = collect(values(pc_scale_kron.observable.terms))
    @test abs(coeffs_kron[1]) ≈ 3.0
    
    # Test Add (sum of observables)
    obs_add = put(n, 1=>X) + put(n, 2=>Z)
    pc_add = yao2paulipropagation(circ; observable=obs_add)
    @test pc_add.observable isa PauliSum
    @test length(pc_add.observable) == 2
    psum_add = propagate(pc_add)
    @test psum_add isa PauliSum
    
    # Test complex expression (sum with scaled terms)
    obs_complex = kron(n, 1=>X, 2=>Z) + 2.0 * put(n, 3=>Y) + 0.5 * kron(n, 4=>X, 5=>X)
    pc_complex = yao2paulipropagation(circ; observable=obs_complex)
    @test pc_complex.observable isa PauliSum
    @test length(pc_complex.observable) == 3
    psum_complex = propagate(pc_complex)
    @test psum_complex isa PauliSum
end

@testset "propagate with kwargs" begin
    n = 6
    circuit = chain(n, 
        put(n, 1=>Rx(0.5)), 
        put(n, 2=>X),
        put(n, (1,2)=>YaoBlocks.ConstGate.CNOT))
    obs = put(n, 1=>Z)
    
    pc = yao2paulipropagation(circuit; observable=obs)
    
    # Test propagate without kwargs
    psum1 = propagate(pc)
    @test psum1 isa PauliSum
    
    # Test propagate with max_weight
    psum2 = propagate(pc; max_weight=10)
    @test psum2 isa PauliSum
    
    # Test propagate with min_abs_coeff
    psum3 = propagate(pc; min_abs_coeff=1e-10)
    @test psum3 isa PauliSum
    
    # Test propagate with both kwargs
    psum4 = propagate(pc; max_weight=10, min_abs_coeff=1e-10)
    @test psum4 isa PauliSum
    
    # Verify expectation values are similar
    exp1 = real(overlapwithzero(psum1))
    exp2 = real(overlapwithzero(psum2))
    @test exp1 ≈ exp2 atol=1e-6
end

@testset "error cases" begin
    n = 3
    circ = chain(n, put(n, 1=>X))
    
    # Test invalid observable (non-Pauli gate)
    @test_throws AssertionError yao2paulipropagation(circ; observable=put(n, 1=>H))
    
    # Test invalid observable (Hadamard in kron)
    @test_throws Exception yao2paulipropagation(circ; observable=kron(n, 1=>H, 2=>X))
    
    # Test invalid observable (rotation gate)
    @test_throws AssertionError yao2paulipropagation(circ; observable=put(n, 1=>Rx(0.5)))
end

@testset "Base.show" begin
    n = 3
    circ = chain(n, put(n, 1=>X), put(n, 2=>Rx(0.5)))
    obs = put(n, 1=>Z)
    pc = yao2paulipropagation(circ; observable=obs)
    
    # Test that show produces output without error
    io = IOBuffer()
    show(io, pc)
    output = String(take!(io))
    
    @test contains(output, "PauliPropagationCircuit")
    @test contains(output, "Qubits: 3")
    @test contains(output, "Gates: 2")
    @test contains(output, "Observable:")
end

@testset "round-trip with different observables" begin
    nq = 4
    nl = 2
    circuit = tfitrottercircuit(nq, nl)
    thetas = randn(countparameters(circuit))
    
    # Test round-trip with different observable types
    observables = [
        put(nq, 1=>Z),
        kron(nq, 1=>X, 2=>Z),
        2.0 * put(nq, 2=>Y),
        put(nq, 1=>X) + put(nq, 2=>Z)
    ]
    
    for obs in observables
        yaocirc = YaoBlocks.paulipropagation2yao(nq, circuit, thetas)
        pc = yao2paulipropagation(yaocirc; observable=obs)
        
        # Verify structure
        @test pc.n == nq
        @test pc.observable isa PauliSum
        
        # Test back conversion
        yaocirc2 = paulipropagation2yao(pc)
        @test nqubits(yaocirc) == nqubits(yaocirc2)
        
        # Test propagation works
        psum = propagate(pc)
        @test psum isa PauliSum
        exp_val = overlapwithzero(psum)
        @test exp_val isa Number
    end
end

@testset "control blocks" begin
    n = 4
    
    # Test CNOT gate
    circ_cnot = chain(n, 
        put(n, 1=>H),
        control(n, 1, 2=>X),
        put(n, 2=>X)
    )
    obs = put(n, 1=>Z)
    pc_cnot = yao2paulipropagation(circ_cnot; observable=obs)
    
    @test pc_cnot.n == n
    @test length(pc_cnot.gates) == 3
    @test pc_cnot.gates[2] isa CliffordGate
    @test getfield(pc_cnot.gates[2], :symbol) == :CNOT
    
    # Test CZ gate
    circ_cz = chain(n,
        put(n, 1=>H),
        control(n, 1, 2=>Z),
        put(n, 2=>Z)
    )
    pc_cz = yao2paulipropagation(circ_cz; observable=obs)
    
    @test pc_cz.n == n
    @test length(pc_cz.gates) == 3
    @test pc_cz.gates[2] isa CliffordGate
    @test getfield(pc_cz.gates[2], :symbol) == :CZ
    
    # Test round-trip for controlled gates
    circ_back = paulipropagation2yao(pc_cnot)
    @test nqubits(circ_back) == n
    @test length(circ_back) == 3
    
    # Test propagation with control gates
    psum = propagate(pc_cnot)
    @test psum isa PauliSum
    exp_val = real(overlapwithzero(psum))
    @test exp_val isa Real
end

@testset "square root gates (SX, SY)" begin
    n = 3
    
    # Test SX gate (Rx(π/2))
    circ_sx = chain(n,
        put(n, 1=>Rx(π/2)),
        put(n, 2=>X)
    )
    obs = put(n, 1=>Z)
    pc_sx = yao2paulipropagation(circ_sx; observable=obs)
    
    @test pc_sx.n == n
    @test length(pc_sx.gates) == 2
    # First gate should be a frozen rotation (SX is stored as frozen rotation)
    @test pc_sx.gates[1] isa FrozenGate
    @test getfield(pc_sx.gates[1], :gate) isa PauliRotation
    
    # Test SY gate (Ry(π/2))
    circ_sy = chain(n,
        put(n, 1=>Ry(π/2)),
        put(n, 2=>Y)
    )
    pc_sy = yao2paulipropagation(circ_sy; observable=obs)
    
    @test pc_sy.n == n
    @test length(pc_sy.gates) == 2
    @test pc_sy.gates[1] isa FrozenGate
    @test getfield(pc_sy.gates[1], :gate) isa PauliRotation
    
    # Test propagation with square root gates
    psum_sx = propagate(pc_sx)
    @test psum_sx isa PauliSum
    exp_val_sx = real(overlapwithzero(psum_sx))
    @test exp_val_sx isa Real
    
    psum_sy = propagate(pc_sy)
    @test psum_sy isa PauliSum
    exp_val_sy = real(overlapwithzero(psum_sy))
    @test exp_val_sy isa Real
end

@testset "ZZpihalf gate" begin
    n = 4
    
    # Test ZZ(π/2) gate (two-qubit rotation)
    circ_zz = chain(n,
        put(n, 1=>H),
        put(n, (1,2)=>rot(kron(Z, Z), π/2)),
        put(n, 2=>X)
    )
    obs = kron(n, 1=>Z, 2=>Z)
    pc_zz = yao2paulipropagation(circ_zz; observable=obs)
    
    @test pc_zz.n == n
    @test length(pc_zz.gates) == 3
    # ZZ gate should be stored as a frozen rotation
    @test pc_zz.gates[2] isa FrozenGate
    inner_gate = getfield(pc_zz.gates[2], :gate)
    @test inner_gate isa PauliRotation
    @test length(getfield(inner_gate, :qinds)) == 2
    
    # Test propagation with ZZ gate
    psum = propagate(pc_zz)
    @test psum isa PauliSum
    exp_val = real(overlapwithzero(psum))
    @test exp_val isa Real
    
    # Test round-trip conversion
    circ_back = paulipropagation2yao(pc_zz)
    @test nqubits(circ_back) == n
    @test length(circ_back) == 3
end

@testset "combined gates and control blocks" begin
    n = 5
    
    # Test circuit with multiple gate types
    circ = chain(n,
        put(n, 1=>H),
        put(n, 2=>Rx(π/2)),  # SX
        control(n, 1, 2=>X),  # CNOT
        put(n, (2,3)=>rot(kron(Z, Z), π/2)),  # ZZ
        control(n, 3, 4=>Z),  # CZ
        put(n, 5=>Ry(π/2)),  # SY
        put(n, 1=>quantum_channel(DepolarizingError(1, 0.01)))
    )
    
    obs = put(n, 1=>Z) + kron(n, 2=>X, 3=>X)
    pc = yao2paulipropagation(circ; observable=obs)
    
    @test pc.n == n
    @test length(pc.gates) == 7
    @test pc.observable isa PauliSum
    
    # Test propagation
    psum = propagate(pc)
    @test psum isa PauliSum
    exp_val = real(overlapwithzero(psum))
    @test exp_val isa Real
    
    # Test round-trip
    circ_back = paulipropagation2yao(pc)
    @test nqubits(circ_back) == n
    @test length(circ_back) == 7
end

@testset "expectation values with control blocks" begin
    n = 4
    
    # Build a simple entangling circuit
    circ = chain(n,
        put(n, 1=>H),
        control(n, 1, 2=>X),
        control(n, 2, 3=>X),
        put(n, 1=>quantum_channel(DepolarizingError(1, 0.02)))
    )
    
    obs = put(n, 1=>Z)
    pc = yao2paulipropagation(circ; observable=obs)
    
    # Pauli propagation result
    psum = propagate(pc)
    exp_pauli = real(overlapwithzero(psum))
    
    # Compare with exact simulation
    reg = zero_state(n) |> density_matrix
    reg_final = apply!(reg, circ)
    exp_exact = real(expect(obs, reg_final))
    
    # Should be close (within numerical tolerance)
    @test isapprox(exp_pauli, exp_exact, atol=1e-10)
end
