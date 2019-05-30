export num_grover_step, inference_oracle, GroverIter, groverblock, groveriter, prob_match_oracle

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
function target_space(nbit::Int, oracle)
    r = ArrayReg(ones(ComplexF64, 1<<nbit))
    r |> oracle
    real(statevec(r)) .< 0
end

prob_inspace(psi::ArrayReg, ts) = norm(statevec(psi)[ts])^2

"""
    prob_match_oracle(psi, oracle) -> Float64

Return the probability that `psi` matches oracle.
"""
prob_match_oracle(psi::ArrayReg, oracle) = prob_inspace(psi, target_space(nqubits(psi), oracle))

"""
    num_grover_step(psi::ArrayReg, oracle) -> Int

Return number of grover steps needed to match the oracle.
"""
num_grover_step(psi::ArrayReg, oracle) = _num_grover_step(prob_match_oracle(psi, oracle))

_num_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1

"""
    GroverIter{N}

    GroverIter(oracle, ref::ReflectBlock{N}, psi::ArrayReg, niter::Int)

an iterator that perform Grover operations step by step.
An Grover operation consists of applying oracle and Reflection.
"""
struct GroverIter{N}
    psi::ArrayReg
    oracle
    ref::ReflectBlock{N}
    niter::Int
end

groveriter(psi::ArrayReg, oracle, ref::ReflectBlock{N}, niter::Int) where {N} = GroverIter{N}(psi, oracle, ref, niter)
groveriter(psi::ArrayReg, oracle, niter::Int) = groveriter(psi, oracle, ReflectBlock(psi |> copy), niter)
groveriter(psi::ArrayReg, oracle) = groveriter(psi, oracle, ReflectBlock(psi |> copy), num_grover_step(psi, oracle))

function Base.iterate(it::GroverIter, st=1)
    if it.niter + 1 == st
        nothing
    else
        apply!(it.psi, it.oracle)
        apply!(it.psi, it.ref), st+1
    end
end

Base.length(it::GroverIter) = it.niter

"""
    groverblock(oracle, ref::ReflectBlock{N}, niter::Int=-1)
    groverblock(oracle, psi::ArrayReg, niter::Int=-1)

Return a ChainBlock/Sequential as Grover Iteration, the default `niter` will stop at the first optimal step.
"""
function groverblock(oracle::AbstractBlock{N}, ref::ReflectBlock{N}, niter::Int=-1) where {N}
    if niter == -1 niter = num_grover_step(ref.psi, oracle) end
    chain(N, chain(oracle, ref) for i = 1:niter)
end

function groverblock(oracle, ref::ReflectBlock{N}, niter::Int=-1) where {N}
    if niter == -1 niter = num_grover_step(ref.psi, oracle) end
    sequence(sequence(oracle, ref) for i = 1:niter)
end

groverblock(oracle, psi::ArrayReg, niter::Int=-1) = groverblock(oracle, ReflectBlock(psi |> copy), niter)
