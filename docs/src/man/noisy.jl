using Yao; darktheme!()

function add_noise(circuit::ChainBlock, noise_gate)
    blocks = chain(nqubits(circuit))
    for block in subblocks(circuit)
        push!(blocks, block)
        for loc in occupied_locs(block)
            push!(blocks, put(nqubits(circuit), loc=>noise_gate))
        end
    end
    return blocks
end

c = EasyBuild.qft_circuit(5) |> Optimise.flatten_basic
nc = add_noise(c, single_qubit_depolarizing_channel(0.01))
# vizcircuit(nc)

rho = density_matrix(zero_state(5))
r1 = apply(rho, c)
r2 = apply(rho, nc)
fidelity(r1, r2)