using Yao
using YaoBlocks.Optimise: replace_block, standardize

# # Noisy Simulation
# To start, we create a simple circuit that we want to simulate, the one generating the 4-qubit GHZ state $|\psi\rangle = \frac{1}{\sqrt{2}}(|0000\rangle + |1111\rangle)$.
# The code is as follows:
n_qubits = 4
circ = chain(
    put(n_qubits, 1 => H),
    [put(n_qubits, (i, i+1) => ConstGate.CNOT) for i in 1:n_qubits-1]...,
)

# Test Circuit
darktheme!()
vizcircuit(circ)

# The ideal simulation gives the following result:
reg = zero_state(n_qubits) |> circ
samples = measure(reg, nshots=1000)

using CairoMakie
fig = Figure()
ax = Axis(fig[1, 1], xlabel="Bitstring", ylabel="Count")
hist!(ax, map(x -> x.buf, samples))
fig


# Example error probabilities
p_reset = 0.03
p_meas = 0.1
p_gate1 = 0.05

# QuantumError objects
error_reset = KrausChannel(BitFlipError(p_reset))
error_meas = KrausChannel(BitFlipError(p_meas))
error_gate1 = KrausChannel(BitFlipError(p_gate1))
error_gate2 = kron(KrausChannel(BitFlipError(p_gate1)), KrausChannel(BitFlipError(p_gate1)))

# Add errors to noise model
circ_noisy = YaoBlocks.Optimise.replace_block(circ) do x
    if x == H
        chain(H, error_gate1)
    elseif nqubits(x) == 2
        chain(x, error_gate2)
    else
        x
    end
end

# add measurement noise

push!(circ_noisy, repeat(error_meas, n_qubits))

circ_noisy = standardize(circ_noisy)

rho = apply(density_matrix(reg), circ_noisy)
samples = measure(rho, nshots=1000)

using CairoMakie
fig = Figure()
ax = Axis(fig[1, 1], xlabel="Bitstring", ylabel="Count")
hist!(ax, map(x -> x.buf, samples))
fig