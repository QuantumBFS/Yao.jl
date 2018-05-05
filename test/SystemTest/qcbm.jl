# Interface
#import QuCircuit: rotation_block
#import QuCircuit: sequence

include("utils.jl")
include("mmd.jl")
include("hackapi.jl")

#= required APIS
    zero_state(num_bit) => reg

    X(num_bit, 1) |> c(cbit) => block: the function is used for constructing controled gates.
    rotation_block(6) => sequence

    block |> cache => block: cache a block.
    block |> cache(level=1, recursive=False) => block
    cache(block, level=1, recursive=False) => block

    block |> mask(mask) => block: mask out some variable by setting false at specific position.

    sequence() => sequence
    append!(sequence, block) => sequence
    sequence |> scatter_params(params) => sequence

    reg >> sequence => iterator
    iterator >> sequence => iterator
    iterator |> cache_signal(2) => iterator
=#

#=
cache_level (default=10)
    * 1-3, can cache (cached by default)
    * 4:9, cache becomes harder
    * 10, can not cache

if cache_signal (default=3) >= cache_level, then cache.

if user set cache_level, check if it is cacheable and cache/error.
=#
export diff_circuit, run_circuit, loss_function, mmd_gradient
"""
Differenciable circuit.
"""
function diff_circuit(num_bit, num_layer)
    # the entangle block
    entangle_block = sequence()
    for tpl in [(2, 1), (4, 3), (6, 5), (3, 2), (5, 4), (6, 1)]
        append!(entangle_block, X(num_bit, tpl[2]) |> c(tpl[1]))
    end
    entangle_block |> cache   # here, we use default level: 1

    # build the circuit
    circuit = sequence()
    for i in 1:num_layer
        if i!=0
            append!(circuit, entangle_block)
        end
        append!(circuit, rotation_block(num_bit) |> mask(repeat([i!=0, true, i!=num_layer], outer=num_bit)) |> cache(recursive=true))
    end
    return circuit
end


function run_circuit(params::Vector{Float64}, circuit::Sequence, signal::Int)
    #psi = Psi("0"^num_bit) # future
    psi = zero_state(nqubit(circuit))

    # >> returns iterator!
    # >> curry: cache_signal, scatter_params, mask_block
    for info in psi >> (circuit |> scatter_params(params)) |> cache_signal(signal)   # here, cache signal uses default cache threshhold and can be avoided
        println(info)
        println("iblock = ", info["iblock"],
                ", current block = ", info["current"],
                ", next block = ", info["next"],
               )
        if info["cache_info"] == 1
            println("cached new value, it is ", info["cache"])
        elseif info["cache_info"] == 0
            println("used cached value, it is ", info["cache"])
        elseif info["cache_info"] == 2
            println("did not cache/use cached value")
        end
        #=  a possible way to hack the iteration
        if next_block == ...
            for psi >> info["next"]
                ...
            end
        end
        circuit |> mask_block(next_block)
        =#

        #=  a way to get measure information
        if "measure_res" in info
            println("the measurement result is ", info["measure_res"])
        end
        =#
    end
    return psi
end


"""
QCBM loss function.
    we can use
        samples = measure(psi, num_sample=20000)
    to get samples, here, we simply use the exact wave function.
"""
function loss_function(params::Vector{Float64}, circuit::Sequence, kernel::Kernel, ptrain::Vector{Float64})
    prob = run_circuit(params, circuit, 3) |> psi2prob
    println(size(prob), size(ptrain), size(kernel.kernel_matrix))
    prob |> mmd_loss(kernel, ptrain)
end

"""
QCBM gradient function.
"""
function mmd_gradient(params, circuit, kernel, ptrain)
    prob = run_circuit(params, circuit, 3) |> psi2prob

    grad = zeros(params)
    for i=1:length(params)
        params_ = copy(params)
        # pi/2 phase
        params_[i] += pi/2.
        prob_pos = run_circuit(params_, circuit, 0) |> psi2prob
        # -pi/2 phase
        params_[i] -= pi
        prob_neg = run_circuit(params_, circuit, 0) |> psi2prob

        grad_pos = kernel_expect(kernel, prob, prob_pos) - kernel_expect(kernel, prob, prob_neg)
        grad_neg = kernel_expect(kernel, ptrain, prob_pos) - kernel_expect(kernel, ptrain, prob_neg)
        grad[i] = grad_pos - grad_neg
    end
    return grad
end
