# # [Grover Search](@id Grover)
using Yao
using YaoExtensions: variational_circuit
using LinearAlgebra

# ## Grover Step
# A single grover step is consist of applying oracle circuit and reflection circuit.
# The `reflection_circuit` function takes the wave function generator `U` as the input and returns `U|0><0|U'`.
function grover_step!(reg::AbstractRegister, oracle, U::AbstractBlock)
    apply!(reg |> oracle, reflect_circuit(U))
end

function reflect_circuit(gen::AbstractBlock{N}) where N
    reflect0 = control(N, -collect(1:N-1), N=>-Z)
    chain(gen', reflect0, gen)
end

# Compute the propotion of target states to estimate the number of iterations,
# which requires computing the output state.
function solution_state(oracle, gen::AbstractBlock{N}) where N
    reg= zero_state(N) |> gen
    reg.state[real.(statevec(ArrayReg(ones(ComplexF64, 1<<N)) |> oracle)) .> 0] .= 0
    normalize!(reg)
end

function num_grover_step(oracle, gen::AbstractBlock{N}) where N
    reg = zero_state(N) |> gen
    ratio = abs2(solution_state(oracle, gen)'*reg)
    Int(round(pi/4/sqrt(ratio)))-1
end

# #### Run
# First, we define the problem by an oracle, it finds bit string `bit"000001100100"`.
num_bit = 12
oracle = matblock(Diagonal((v = ones(ComplexF64, 1<<num_bit); v[Int(bit"000001100100")+1]*=-1; v)))

# then solve the above problem
gen = repeat(num_bit, H, 1:num_bit)
reg = zero_state(num_bit) |> gen

target_state = solution_state(oracle, gen)

for i = 1:num_grover_step(oracle, gen)
    grover_step!(reg, oracle, gen)
    overlap = abs(reg'*target_state)
    println("step $(i-1), overlap = $overlap")
end

# ## Rejection Sampling
# In practise, it is often not possible to determine the number of iterations before actual running.
# we can use rejection sampling technique to avoid estimating the number of grover steps.

using Random; Random.seed!(2)  #src

# In a single try, we `apply` the grover algorithm for `nstep` times.
function single_try(oracle, gen::AbstractBlock{N}, nstep::Int; nbatch::Int) where N
    reg = zero_state(N+1; nbatch=nshot)
    focus!(reg, 1:N) do r
        r |> gen
        for i = 1:nstep
            grover_step!(r, oracle, gen)
        end
        return r
    end
    reg |> checker
    res = measure_remove!(reg, (N+1))
    return res, reg
end

# After running the grover search, we have a checker program that flips the ancilla qubit
# if the output is the desired value, we assume the checker program can be implemented in polynomial time.
# to gaurante the output is correct.
# We contruct a checker "program", if the result is correct, flip the ancilla qubit
ctrl = -collect(1:num_bit); ctrl[[3,6,7]] *= -1
checker = control(num_bit+1,ctrl, num_bit+1=>X)

# The register is batched, with batch dimension `nshot`.
# [`focus!`](@ref Yao.focus!) views the first 1-N qubts as system.
# For a batched register, [`measure_remove!`](@ref Yao.measure_remove!)
# returns a vector of bitstring as output.

# #### Run
maxtry = 100
nshot = 3

for nstep = 0:maxtry
    println("number of iter = $nstep")
    res, reg = single_try(oracle, gen, nstep; nbatch=3)

    ## success!
    if any(==(1), res)
        overlap_final = viewbatch(reg, findfirst(==(1), res))'*target_state
        println("success, overlap = $(overlap_final)")
        break
    end
end

# The final state has an overlap of `1` with the target state.

# ## Amplitude Amplification
# Given a circuit to generate a state,
# now we want to project out the subspace with [1,3,5,8,9,11,12] fixed to 1 and [4,6] fixed to 0.
# We can construct an oracle
evidense = [1, 3, -4, 5, -6, 8, 9, 11, 12]
function inference_oracle(nbit::Int, locs::Vector{Int})
    control(nbit, locs[1:end-1], abs(locs[end]) => (locs[end]>0 ? Z : -Z))
end
oracle = inference_oracle(nqubits(reg), evidense)

# We use a variational circuit generator defined in `YaoExtensions`
gen = dispatch!(variational_circuit(num_bit), :random)
reg = zero_state(num_bit) |> gen

# #### Run
solution = solution_state(oracle, gen)
for i = 1:num_grover_step(oracle, gen)
    grover_step!(reg, oracle, gen)
    println("step $(i-1), overlap = $(abs(reg'*solution))")
end
