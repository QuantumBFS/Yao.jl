export num_grover_step, inference_oracle, GroverIter, groverblock, groveriter!, prob_match_oracle

"""
    inference_oracle([nbit::Int,] locs::Vector{Int}) -> ControlBlock

A simple inference oracle, e.g. inference([-1, -8, 5]) is a control block that flip the bit if values of bits on position [1, 8, 5] match [0, 0, 1].
"""
inference_oracle(locs::Vector{Int}) = control(locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : chain(phase(π), Z)))
inference_oracle(nbit::Int, locs::Vector{Int}) = inference_oracle(locs)(nbit)

"""
    target_space(oracle) -> Vector{Bool}

Return a mask, that disired subspace of an oracle are masked true.
"""
target_space(num_bit::Int, oracle) = (register(ones(ComplexF64, 1<<num_bit)) |> oracle |> statevec |> real) .< 0
prob_inspace(psi::DefaultRegister, ts) = norm(statevec(psi)[ts])^2

"""
    prob_match_oracle(psi, oracle) -> Float64

Return the probability that `psi` matches oracle.
"""
prob_match_oracle(psi::DefaultRegister, oracle) = prob_inspace(psi, target_space(nqubits(psi), oracle))

"""
    num_grover_step(psi::DefaultRegister, oracle) -> Int

Return number of grover steps needed to match the oracle.
"""
num_grover_step(psi::DefaultRegister, oracle) = _num_grover_step(prob_match_oracle(psi, oracle))

_num_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1

"""
    GroverIter{N, T}

    GroverIter(oracle, ref::ReflectBlock{N, T}, psi::DefaultRegister, niter::Int)

an iterator that perform Grover operations step by step.
An Grover operation consists of applying oracle and Reflection.
"""
struct GroverIter{N, T}
    psi::DefaultRegister
    oracle
    ref::ReflectBlock{N, T}
    niter::Int
end
groveriter!(psi::DefaultRegister, oracle, ref::ReflectBlock{N, T}, niter::Int) where {N, T} = GroverIter{N, T}(psi, oracle, ref, niter)
groveriter!(psi::DefaultRegister, oracle, niter::Int) = groveriter!(psi, oracle, ReflectBlock(psi |> copy), niter)
groveriter!(psi::DefaultRegister, oracle) = groveriter!(psi, oracle, ReflectBlock(psi |> copy), num_grover_step(psi, oracle))

Base.next(iter::GroverIter, state::Int) = apply!(iter.psi |> iter.oracle, iter.ref), state+1
Base.start(iter::GroverIter) = 1
Base.done(iter::GroverIter, state::Int) = iter.niter+1 == state
Base.length(iter::GroverIter) = iter.niter

"""
    groverblock(oracle, ref::ReflectBlock{N, T}, niter::Int=-1)
    groverblock(oracle, psi::DefaultRegister, niter::Int=-1)

Return a ChainBlock/Sequential as Grover Iteration, the default `niter` will stop at the first optimal step.
"""
function groverblock(oracle::MatrixBlock{N, T}, ref::ReflectBlock{N, T}, niter::Int=-1) where {N, T}
    if niter == -1 niter = num_grover_step(ref.psi, oracle) end
    chain(N, chain(oracle, ref) for i = 1:niter)
end

function groverblock(oracle, ref::ReflectBlock{N, T}, niter::Int=-1) where {N, T}
    if niter == -1 niter = num_grover_step(ref.psi, oracle) end
    sequence(sequence(oracle, ref) for i = 1:niter)
end

groverblock(oracle, psi::DefaultRegister, niter::Int=-1) = groverblock(oracle, ReflectBlock(psi |> copy), niter)
