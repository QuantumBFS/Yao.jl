using Compat.Test

import QuCircuit: Cache, rand_state, state, focus!,
    X, Y, Z, gate, phase, cache, focus, address
# Interface
import QuCircuit: sequence

include("hackapi.jl")

num_bit = 4
ghz_state = zeros(Complex128, 1<<num_bit)
ghz_state[1] = 1/sqrt(2)
ghz_state[end] = -1/sqrt(2)

@testset "ghz" begin
    circuit = sequence(
                       X(num_bit, 1),
                       H(num_bit, 2:num_bit),
                       c(2)(X(num_bit, 1)),
                       c(4)(X(num_bit, 3)),
                       c(3)(X(num_bit, 1)),
                       c(4)(X(num_bit, 3)),
                       H(num_bit, 1:num_bit),
                      )
    psi = zero_states(num_bit)

    for info in psi >> circuit
        println("iblock = ", info["iblock"],
                ", current block = ", info["current"],
                ", next block = ", info["next"],
               )
    end
    @test psi == ghz_state
end
