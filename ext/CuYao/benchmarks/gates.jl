using Yao, CuYao, CUDA
using BenchmarkTools

reg = rand_state(12; nbatch=1000)
creg = reg |> cu
@benchmark CUDA.@sync creg |> put(12, 3=>Z)
@benchmark CUDA.@sync creg |> put(12, 3=>X)
@benchmark reg |> put(12, 3=>Z)
@benchmark CUDA.@sync creg |> control(12, 6, 3=>X)
@benchmark reg |> control(12, 6, 3=>X)
@benchmark CUDA.@sync creg |> put(12, 3=>rot(X, 0.3))
@benchmark reg |> put(12, 3=>rot(X, 0.3))

reg = rand_state(20)
creg = reg |> cu
g = swap(20, 7, 2)
g = put(20, (7, 2)=>matblock(rand_unitary(4)))
@benchmark reg |> g
@benchmark CUDA.@sync creg |> g
