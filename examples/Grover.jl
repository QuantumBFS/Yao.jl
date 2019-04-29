# # Grover Search
using Yao
using LinearAlgebra
using QuAlgorithmZoo: groveriter, inference_oracle, prob_match_oracle

# ## Target Space and Evidense
num_bit = 12
oracle = matblock(Diagonal((v = ones(1<<num_bit); v[100:101]*=-1; v)))
target_state = zeros(1<<num_bit); target_state[100:101] .= sqrt(0.5)

# now we want to search the subspace with [1,3,5,8,9,11,12] fixed to 1 and [4,6] fixed to 0.
evidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]

# ## Search
# then solve the above problem
it = groveriter(uniform_state(num_bit), oracle)
for (i, psi) in enumerate(it)
    overlap = abs(statevec(psi)'*target_state)
    println("step $(i-1), overlap = $overlap")
end

# ## Inference Example
# we have a state psi0, we know how to prepair it
psi = rand_state(num_bit)

"""
Doing Inference, psi is the initial state, we want to search target space with specific evidense.
e.g. evidense [1, -3, 6] means the [1, 3, 6]-th bits take value [1, 0, 1].
"""
oracle_infer = inference_oracle(evidense)(nqubits(psi))
it = groveriter(psi, oracle_infer)
for (i, psi) in enumerate(it)
    p_target = prob_match_oracle(psi, oracle_infer)
    println("step $(i-1), overlap^2 = $p_target")
end
