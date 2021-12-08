# # CUDA acceleration of Quantum Simulation

# For example, a SWAP gate can be instructed on a GPU register like

# ```julia
# function instruct!(reg::GPUReg, ::Val{:SWAP}, locs::Tuple{Int,Int})
#     b1, b2 = locs
#     state = statevec(reg)
#     mask1 = bmask(b1)
#     mask2 = bmask(b2)

#     function kf(state, mask1, mask2)
#         inds = ((blockIdx().x-1) * blockDim().x + threadIdx().x,
#                        (blockIdx().y-1) * blockDim().y + threadIdx().y)
#         b = inds[1]-1
#         c = inds[2]
#         c <= size(state, 2) || return nothing
#         if b&mask1==0 && b&mask2==mask2
#             i = b+1
#             i_ = b  (mask1|mask2) + 1
#             temp = state[i, c]
#             state[i, c] = state[i_, c]
#             state[i_, c] = temp
#         end
#         nothing
#     end
#     X, Y = cudiv(size(state)...)
#     @cuda threads=X blocks=Y kf(state, mask1, mask2)
#     state
# end
# ```

# Here, we devide the threads and blocks into a two dimensional grid with a same shape as the input GPUReg storage (i.e. ``2^a\times 2^rB``).
# Only if two qubits at `locs` are $0$ and $1$ respectively, they are exchanged, otherwise do nothing.
# Although $3/4$ of threads are idle and plenty room for optimization, from this example, we see how easy CUDA programming is with
# [CUDAnative](https://github.com/JuliaGPU/CUDAnative.jl).
