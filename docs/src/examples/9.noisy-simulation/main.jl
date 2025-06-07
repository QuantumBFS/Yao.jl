using Yao
using YaoBlocks.Optimise: replace_block, standardize
using CairoMakie

# # Noisy Simulation
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
samples = measure(reg, nshots=1000)

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

push!(circ_noisy, repeat(error_meas, n_qubits)) # add measurement noise

# Convert the circuit to a standard form
circ_noisy = standardize(circ_noisy)

# simulate the noisy circuit
rho = apply(density_matrix(reg), circ_noisy)
samples = measure(rho, nshots=1000)

# Visualize the results
hist(map(x -> x.buf, samples))