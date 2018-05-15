using Compat.Test

import QuCircuit: Sequence, AbstractBlock
import QuCircuit: rand_state, zero_state, state, focus!,
    X, Y, Z, H, C, gate, phase, focus, address, chain
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!


mutable struct Print <: AbstractBlock
    stream::String
end
apply!(reg, block::Print) = (block.stream = string(reg); reg)

@testset "sequence" begin

    test_print = Print("")
    program = Sequence(
        kron(5, gate(:X), gate(:Y)),
        kron(5, gate(:X), 4=>gate(:Y)),
        test_print,
    )

    reg = rand_state(5)
    apply!(reg, program)
    @test test_print.stream == string(reg)
end


@testset "circuit plan" begin

    reg = rand_state(4)
    c = [
        kron(gate(:X), gate(:Z), gate(:Z), gate(:X)),
        focus(2, 3),
        kron(gate(:X), gate(:Z)),
    ]

    for (i, info) in enumerate(reg >> c[1] >> c[2] >> c[3])
        @test info["iblock"] == i
        @test info["current"] == c[info["iblock"]]
    end

end

# @testset "check example: ghz" begin
#     num_bits = 4
#     ghz_state = zeros(Complex128, 1<<num_bits)
#     ghz_state[1] = 1 / sqrt(2)
#     ghz_state[end] = -1 / sqrt(2)

#     psi = zero_state(4)

#     circuit = Sequence(
#         X(num_bits, 1),
#         H(num_bits, 2:num_bits),
#         X(1) |> C(num_bits, 2),
#         X(3) |> C(num_bits, 4),
#         X(1) |> C(num_bits, 3),
#         X(3) |> C(num_bits, 4),
#         H(num_bits, 1:num_bits),
#     )

#     for info in psi >> circuit
#     end
#     @test state(psi) ≈ ghz_state
# end
