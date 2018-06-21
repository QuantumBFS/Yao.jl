using Yao
using Yao.Zoo
using Yao.Blocks

c = diff_circuit(4, 3, [1=>3, 2=>4, 2=>3, 4=>1])
println(c)
rots = collect_rotblocks(c)

obs = kron(nqubits(c), 2=>X)
opgrad(obs, c)

vstatgrad(kernel::AbstractArray, circuit::AbstractBlock, reg0::AbstractRegister, gates::Vector{RotationGate}) = 1


circuit_gan(n::Int, depth_gen::Int, depth_disc::Int, pairs::Vector) = chain(n, diff_circuit(n, depth_gen, pairs), AddBit(1), diff_circuit(n+1, depth_disc, pairs))

using Compat.Test
circuit_gan(3, 1,1, [1=>2, 2=>3])
