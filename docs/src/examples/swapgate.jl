# # Dive into the implementation of CuReg.
# `CuYao.jl` implements the quantum simulation on GPU.
# Its performence is guaranted by the clever design of [CUDAnative.jl](https://github.com/JuliaGPU/CUDAnative.jl)

using YaoArrayRegister
using CUDAnative, CuArrays
using BitBasis: log2dim1, itercontrol, bmask

"""
CUDA implementaion of `SWAP` instruction.
"""
function YaoArrayRegister.instruct!(state::CuMatrix, ::Val{:SWAP}, locs::Tuple{Int,Int})
    b1, b2 =locs
    ic = itercontrol(log2dim1(state), [b1, b2], [0, 1])
    mask12 = bmask(b1, b2)
    function kf(state, ic, mask12)
        i1 = (blockIdx().x-1) *blockDim().x +threadIdx().x
        i2 = (blockIdx().y-1) *blockDim().y +threadIdx().y
        i2 <= size(state, 2) || return nothing
        b = ic[i1]
        i = b+1
        i_ = b ⊻ mask12 +1
        temp =state[i, i2]
        state[i, i2] =state[i_, i2]
        state[i_, i2] =temp
        nothing
    end
    X, Y = cudiv(length(ic), size(state, 2))
    @cuda threads=X blocks=Y kf(state, ic, mask12)
    state
end

# we designed itercontrol(nbits, locs, vals)
# to iterate over controlled binary space efficiently. It is
# a crucial tool for implementing CPU and CUDA
# instructions for the simulation. e.g iterating over
# a subspace of a 5 qubit basis with qubits 2, 4, 1
# fixed to 0, 1, 1 gives 01001 (9), 01101 (13), 11001
# (25), 11101(29)


# The utility function `cudiv` computes the number of threads and blocks to launch,
# which is defined as
@inline function cudiv(x::Int, y::Int)
    max_threads = 256
    threads_x = min(max_threads, x)
    threads_y = min(max_threads ÷ threads_x, y)
    threads = (threads_x, threads_y)
    blocks = ceil.(Int, (x, y) ./ threads)
    threads, blocks
end

using Test
reg0 = rand_state(10)
reg1 = ArrayReg(CuArray(reg0.state))
st1 = instruct!(reg1, Val(:SWAP), (3,5))
st2 = instruct!(copy(reg0), Val(:SWAP), (3,5))
@test st1 ≈ st2
