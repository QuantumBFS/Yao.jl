# Grover Search and Quantum Inference

## Grover Search
![grover](../assets/figures/grover.png)

First, we construct the reflection block ``R(|\psi\rangle) = 2|\psi\rangle\langle\psi|-1``, given we know how to construct ``|\psi\rangle=A|0\rangle``.
Then it equivalent to construct $R(|\psi\rangle) = A(2|0\rangle\langle 0|-1)A^\dagger$
```@example Grover
using Yao
using Yao.Blocks
using Compat
using Compat.Test
using StatsBase

"""
A way to construct oracle, e.g. inference_oracle([1,2,-3,5]) will
invert the sign when a qubit configuration matches: 1=>1, 2=>1, 3=>0, 5=>1.
"""
function inference_oracle(locs::Vector{Int})
    control(locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : chain(phase(π), Z)))
end

function reflectblock(A::MatrixBlock{N}) where N
    chain(N, A |> adjoint, inference_oracle(-collect(1:N)), A)
end

nbit = 12
A = repeat(nbit, H)
ref = reflectblock(A)

@testset "test reflect" begin
    reg = rand_state(nbit)
    ref_vec = apply!(zero_state(nbit), A) |> statevec
    v0 = reg |> statevec
    @test -2*(ref_vec'*v0)*ref_vec + v0 ≈ apply!(copy(reg), ref) |> statevec
end
```
Then we define the oracle and target state

```@example Grover
# first, construct the oracle with desired state in the range 100-105.
oracle!(reg::DefaultRegister) = (reg.state[100:105,:]*=-1; reg)

# transform it into a function block, so it can be put inside a `Sequential`.
fb_oracle = FunctionBlock{:Oracle}(reg->oracle!(reg))

"""
ratio of components in a wavefunction that flip sign under oracle.
"""
function prob_match_oracle(psi::DefaultRegister, oracle)
    fliped_reg = apply!(register(ones(Complex128, 1<<nqubits(psi))), oracle)
    match_mask = fliped_reg |> statevec |> real .< 0
    norm(statevec(psi)[match_mask])^2
end

# uniform state as initial state
psi0 = apply!(zero_state(nbit), A)

# the number of grover steps that can make it reach first maximum overlap.
num_grover_step(prob::Real) = Int(round(pi/4/sqrt(prob)))-1
niter = num_grover_step(prob_match_oracle(psi0, fb_oracle))

# construct the whole circuit
gb = sequence(sequence(fb_oracle, ref) for i = 1:niter)
```

Now, let's start training
```@example Grover
for (i, blk) in enumerate(gb)
    apply!(psi0, blk)
    overlap = prob_match_oracle(psi0, fb_oracle)
    println("step $(i-1), overlap = $overlap")
end
```

The above is the standard Grover Search algorithm, it can find target state in $O(\sqrt N)$ time, with $N$ the size of an unordered database.
Similar algorithm can be used in more useful applications, like inference, i.e. get conditional probability distribution $p(x|y)$ given $p(x, y)$.

```@example Grover
function rand_circuit(nbit::Int, ngate::Int)
    circuit = chain(nbit)
    gate_list = [X, H, Ry(0.3), CNOT]
    for i = 1:ngate
        gate = rand(gate_list)
        push!(circuit, put(nbit, (sample(1:nbit, nqubits(gate),replace=false)...,)=>gate))
    end
    circuit
end
A = rand_circuit(nbit, 200)
psi0 = apply!(zero_state(nbit), A)

# now we want to search the subspace with [1,3,5,8,9,11,12]
# fixed to 1 and [4,6] fixed to 0.
evidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]

"""
Doing Inference, psi is the initial state,
the target is to search target space with specific evidense.
e.g. evidense [1, -3, 6] means the [1, 3, 6]-th bits take value [1, 0, 1].
"""
oracle_infer = inference_oracle(evidense)(nqubits(psi0))

niter = num_grover_step(prob_match_oracle(psi0, oracle_infer))
gb_infer = chain(nbit, chain(oracle_infer, reflectblock(A)) for i = 1:niter);
```

Now, let's start training
```@example Grover
for (i, blk) in enumerate(gb_infer)
    apply!(psi0, blk)
    p_target = prob_match_oracle(psi0, oracle_infer)
    println("step $(i-1), overlap^2 = $p_target")
end
```

Congratuations! You get state of art quantum inference circuit!
