using Yao
using Yao.Zoo: GroverIter, inference_oracle, prob_match_oracle

num_bit = 12
oracle(reg::DefaultRegister) = (reg.state[100:101,:]*=-1; reg)
target_state = zeros(1<<num_bit); target_state[100:101] = sqrt(0.5)

# then solve the above problem
it = GroverIter(oracle, uniform_state(num_bit))
for (i, psi) in it
    overlap = abs(statevec(psi)'*target_state)
    println("step $(i-1), overlap = $overlap")
end

# we have a state psi0, we know how to prepair it
psi = rand_state(num_bit)

# now we want to search the subspace with [1,3,5,8,9,11,12] fixed to 1 and [4,6] fixed to 0.
evidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]

"""
Doing Inference, psi is the initial state, we want to search target space with specific evidense.
e.g. evidense [1, -3, 6] means the [1, 3, 6]-th bits take value [1, 0, 1].
"""
oracle_infer = inference_oracle(evidense)(nqubits(psi))
it = GroverIter(oracle_infer, psi)
for (i, psi) in it
    p_target = prob_match_oracle(psi, oracle_infer)
    println("step $(i-1), overlap^2 = $p_target")
end
