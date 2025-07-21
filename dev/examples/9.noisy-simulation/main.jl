# # Noisy Simulation

using Yao
using YaoBlocks.Optimise: replace_block
using CairoMakie

# To start, we create a simple circuit that we want to simulate, the one generating the 4-qubit GHZ state $|\psi\rangle = \frac{1}{\sqrt{2}}(|0000\rangle + |1111\rangle)$.
# The code is as follows:
n_qubits = 4
circ = chain(
    put(n_qubits, 1 => H),
    [control(n_qubits, i, i+1 => X) for i in 1:n_qubits-1]...,
)

# Visualize the circuit
vizcircuit(circ)

# The ideal simulation gives the following result:
reg = zero_state(n_qubits) |> circ
samples = measure(reg, nshots=1000);

# Visualize the results
hist(map(x -> x.buf, samples))

# Add errors to noise model
circ_noisy = Optimise.replace_block(circ) do x
    if x isa PutBlock && length(x.locs) == 1
        chain(x, put(nqubits(x), x.locs => quantum_channel(BitFlipError(0.1))))
    elseif x isa ControlBlock && length(x.ctrl_locs) == 1 && length(x.locs) == 1
        chain(x, put(nqubits(x), (x.ctrl_locs..., x.locs...) => kron(quantum_channel(BitFlipError(0.1)), quantum_channel(BitFlipError(0.1)))))
    else
        x
    end
end

push!(circ_noisy, repeat(quantum_channel(BitFlipError(0.05)), n_qubits)) # add measurement noise

# simulate the noisy circuit
rho = apply(density_matrix(reg), circ_noisy)
samples = measure(rho, nshots=1000);

# Visualize the results
hist(map(x -> x.buf, samples))

# # Error Types and Quantum Channels
# 
# Yao provides various types of quantum errors and their corresponding quantum channel representations. 
# Let's explore the different error types available:

# ## 1. Bit Flip Error
# A bit flip error with probability p applies X gate with probability p
bit_flip = BitFlipError(0.1)
bit_flip_channel = quantum_channel(bit_flip)
println("Bit Flip Error Channel: ", bit_flip_channel)

# ## 2. Phase Flip Error  
# A phase flip error with probability p applies Z gate with probability p
phase_flip = PhaseFlipError(0.1)
phase_flip_channel = quantum_channel(phase_flip)
println("Phase Flip Error Channel: ", phase_flip_channel)

# ## 3. Depolarizing Error
# A depolarizing error with probability p applies X, Y, or Z gate with equal probability p/3
depolarizing = DepolarizingError(1, 0.1)
depolarizing_channel = quantum_channel(depolarizing)
println("Depolarizing Error Channel: ", depolarizing_channel)

# ## 4. Pauli Error
# A Pauli error with probabilities px, py, pz for X, Y, Z gates respectively
pauli_error = PauliError(0.05, 0.03, 0.02)
pauli_channel = quantum_channel(pauli_error)
println("Pauli Error Channel: ", pauli_channel)

# ## 5. Reset Error
# A reset error that resets qubits to |0⟩ or |1⟩ with given probabilities
reset_error = ResetError(0.1, 0.05)  # p0, p1
reset_channel = quantum_channel(reset_error)
println("Reset Error Channel: ", reset_channel)

# ## 6. Thermal Relaxation Error
# Models decoherence with T1 and T2 times
thermal_relaxation = ThermalRelaxationError(100.0, 200.0, 1.0, 0.0)
thermal_channel = quantum_channel(thermal_relaxation)
println("Thermal Relaxation Error Channel: ", thermal_relaxation)

# ## 7. Amplitude Damping Error
# Models energy loss to environment
amplitude_damping = AmplitudeDampingError(0.1)
amplitude_channel = quantum_channel(amplitude_damping)
println("Amplitude Damping Error Channel: ", amplitude_damping)

# ## 8. Phase Damping Error
# Models pure dephasing
phase_damping = PhaseDampingError(0.1)
phase_channel = quantum_channel(phase_damping)
println("Phase Damping Error Channel: ", phase_damping)

# ## 9. Phase-Amplitude Damping Error
# Combines both amplitude and phase damping
phase_amplitude_damping = PhaseAmplitudeDampingError(0.1, 0.05, 0.0)
phase_amplitude_channel = quantum_channel(phase_amplitude_damping)
println("Phase-Amplitude Damping Error Channel: ", phase_amplitude_damping)

# ## 10. Coherent Error
# A deterministic error represented by a quantum gate
coherent_error = CoherentError(X)
coherent_channel = quantum_channel(coherent_error)
println("Coherent Error Channel: ", coherent_error)

# # Channel Representations
# 
# Each error type can be converted to different channel representations:

# ## Kraus Channel Representation
# Represents the channel as a set of Kraus operators
bit_flip_kraus = KrausChannel(bit_flip)
println("Bit Flip Kraus Operators:")
for (i, op) in enumerate(bit_flip_kraus.operators)
    println("K$i = ", mat(op))
end

# ## Mixed Unitary Channel Representation  
# Represents the channel as a convex combination of unitary operators
bit_flip_mixed = MixedUnitaryChannel(bit_flip)
println("Bit Flip Mixed Unitary Channel:")
for (i, (prob, gate)) in enumerate(zip(bit_flip_mixed.probs, bit_flip_mixed.operators))
    println("p$i = $prob, U$i = ", mat(gate))
end

# ## Superoperator Representation
# Represents the channel as a superoperator matrix
bit_flip_superop = SuperOp(bit_flip)
println("Bit Flip Superoperator Matrix:")
println(bit_flip_superop.superop)

# # Example: Comparing Different Error Types
# 
# Let's compare how different error types affect a simple circuit:

# Create a simple test circuit
test_circ = chain(2, put(1=>H), control(2, 1=>X))

# Test different error types
error_types = [
    ("Bit Flip", BitFlipError(0.1)),
    ("Phase Flip", PhaseFlipError(0.1)), 
    ("Depolarizing", DepolarizingError(1, 0.1)),
    ("Amplitude Damping", AmplitudeDampingError(0.1)),
    ("Phase Damping", PhaseDampingError(0.1))
]

println("\nComparing different error types on a 2-qubit circuit:")
for (name, error) in error_types
    ## Add error after each gate
    noisy_circ = replace_block(test_circ) do block
        if block isa PutBlock && length(block.locs) == 1
            chain(block, put(nqubits(block), block.locs => quantum_channel(error)))
        elseif block isa ControlBlock && length(block.ctrl_locs) == 1 && length(block.locs) == 1
            chain(block, put(nqubits(block), (block.ctrl_locs..., block.locs...) => 
                kron(quantum_channel(error), quantum_channel(error))))
        else
            block
        end
    end
    
    ## Simulate
    rho = noisy_simulation(zero_state(2), noisy_circ)
    fid = fidelity(rho, apply(density_matrix(zero_state(2)), test_circ))
    println("$name Error: Fidelity = $(round(fid, digits=3))")
end
