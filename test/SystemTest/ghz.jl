using Compat.Test

import QuCircuit: Cache, rand_state, state, focus!,
    X, Y, Z, gate, phase, cache, focus, address
# Interface
import QuCircuit: sequence

num_bit = 4
ghz_state = zeros(Complex128, 1<<num_bit)
ghz_state[1] = 1/sqrt(2)
ghz_state[end] = -1/sqrt(2)

struct Iter
end

import Base.Iterators: start, next, done
d = Dict("wavefunction"=>ghz_state, "iblock"=>2, "current"=> 3, "next"=>6)
function start(iter::Iter)
    return 0
end
function next(iter::Iter, state)
    return d, state+1
end
function done(iter::Iter, state)
    return state == 4
end


@testset "ghz" begin
    #=
    circuit = sequence(
                       X(num_bit, 1),
                       H(num_qubit, 2:num_qubit),
                       c(2)(X(num_qubit, 1)),
                       c(4)(X(num_qubit, 3)),
                       c(3)(X(num_qubit, 1)),
                       c(4)(X(num_qubit, 3)),
                       H(num_qubit, 1:num_qubit),
                      )
    psi = Register("0"^num_qubit)
    =#

    local final_state
    for info in Iter()#psi >> circuit
        println("iblock = ", info["iblock"],
                ", current block = ", info["current"],
                ", next block = ", info["next"],
                ", wave function is ", info["wavefunction"],
               )
        final_state = info["wavefunction"]
    end
    @test final_state == ghz_state
end
