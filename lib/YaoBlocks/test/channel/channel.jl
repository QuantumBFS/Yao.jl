using Test

include("errortypes.jl")
include("superop.jl")
include("kraus.jl")
include("mixed_unitary_channel.jl")

@testset "add noise and noisy simulation" begin
    # simulate a clean circuit
    reg = rand_state(2)
    circuit = chain(put(2, 1=>X), put(2, 2=>X))
    @test noisy_simulation(reg, circuit) ≈ density_matrix(apply(reg, circuit))

    # add noise to a circuit
    reg = rand_state(2)
    circuit = chain(put(2, 1=>X), put(2, 2=>X))
    ncirc = Optimise.replace_block(circuit) do block
        if block isa PutBlock && length(block.locs) == 1
            return chain(block, put(nqubits(block), block.locs => quantum_channel(BitFlipError(0.1))))
        else
            return block
        end
    end
    @info "simulating noisy circuit: $ncirc"
    @test ncirc isa ChainBlock && length(ncirc) == 2 && length(ncirc[1]) == 2 && length(ncirc[2]) == 2
    cn = quantum_channel(BitFlipError(0.1))
    expected_ncirc = chain(put(2, 1=>X), put(2, 1=>cn), put(2, 2=>X), put(2, 2=>cn))
    @test noisy_simulation(reg, ncirc) ≈ apply(density_matrix(reg), expected_ncirc)
end