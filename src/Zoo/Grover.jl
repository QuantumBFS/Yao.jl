export num_grover_step, inference_oracle, prob_match, GroverIter

"""
    inference_oracle(locs::Vector{Int}) -> ControlBlock

A simple inference oracle, e.g. inference([-1, -8, 5]) is a control block that flip the bit if values of bits on position [1, 8, 5] match [0, 0, 1].
"""
inference_oracle(locs::Vector{Int}) = control(locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : chain(phase(π), Z)))

"""
    target_space(oracle) -> Vector{Bool}

Return a mask, that disired subspace of an oracle are masked true.
"""
target_space(num_bit::Int, oracle) = (register(ones(Complex128, 1<<num_bit)) |> oracle |> statevec |> real) .< 0
prob_inspace(psi::AbstractRegister, ts) = norm(statevec(psi)[ts])^2

"""
    prob_match_oracle(psi, oracle) -> Float64

Return the probability that `psi` matches oracle.
"""
prob_match_oracle(psi::AbstractRegister, oracle) = prob_inspace(psi, target_space(nqubits(psi), oracle))

"""
    num_grover_step(prob::Real) -> Int

Return number of grover steps to obtain the maximum overlap with target state.

Input parameter `prob` is the overlap between `target state space` and initial state ``|\psi\ranlge``,
which means the probability of obtaining `true` on initial state.
"""
num_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1

"""
    GroverIter{AUTOSTOP, N, T}

    GroverIter{AUTOSTOP}(oracle, ref::ReflectBlock{N, T}, psi::AbstractRegister) -> GroverIter{N, T}

Return an iterator that perform Grover operations step by step.
An Grover operation consists of applying oracle and Reflection.

If `AUTOSTOP` is true, it will stop when the first maximum of state matches the oracle.
"""
struct GroverIter{AUTOSTOP, N, T}
    oracle
    ref::ReflectBlock{N, T}
    psi::AbstractRegister
    niter::Int
end
GroverIter{AUTOSTOP}(oracle, ref::ReflectBlock{N, T}, psi::AbstractRegister) where {AUTOSTOP, N, T} = GroverIter{AUTOSTOP, N, T}(oracle, ref, psi, AUTOSTOP ? num_grover_step(prob_match_oracle(psi, oracle)) : -1)
GroverIter{AUTOSTOP}(oracle, psi::AbstractRegister{B, T}) where {AUTOSTOP, B, T} = GroverIter{AUTOSTOP}(oracle, ReflectBlock(psi |> statevec |> copy), psi)
GroverIter(oracle, psi::AbstractRegister) = GroverIter{true}(oracle, psi)

Base.next(iter::GroverIter, state::Int) = (state, apply!(iter.psi |> iter.oracle, iter.ref)), state+1
Base.start(iter::GroverIter) = 1
Base.done(iter::GroverIter{false}, state::Int) = false
Base.done(iter::GroverIter{true}, state::Int) = iter.niter+1 == state
Base.iteratorsize(::Type{GroverIter{AUTOSTOP}}) where AUTOSTOP = AUTOSTOP ? Base.HasLength() : Base.IsInfite()
Base.length(iter::GroverIter{true}) = iter.niter
Base.length(iter::GroverIter{false}) = Inf
