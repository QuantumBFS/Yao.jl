using BenchmarkTools
using Yao.Intrisics

const nbit = 16
const V = randn(ComplexF64, 1<<nbit)
const res4 = copy(V)

it = itercontrol(nbit, [3],[1])
@benchmark controldo(x->swaprows!($res4, x+1, x-3), $it)
@benchmark for i in $it swaprows!($res4, i+1, i-3) end
@benchmark controldo($(x->x), $it)
