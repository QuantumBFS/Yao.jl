# # Variational Quantum Eigen Solver

using Yao, Yao.AD, YaoExtensions


using YaoExtensions: get_diffblocks, _perturb
using StatsBase

function _expect(op::AbstractBlock, reg::ArrayReg; nshots=nothing)
    if nshots === nothing
        expect(op, reg)
    else
        mean(measure(op, copy(reg); nshots=nshots))
    end
end

@inline function my_faithful_grad(op::AbstractBlock, pair::Pair{<:ArrayReg, <:AbstractBlock}; nshots=nothing)
    map(get_diffblocks(pair.second)) do diffblock
        r1, r2 = _perturb(()->_expect(op, copy(pair.first) |> pair.second; nshots=nshots) |> real, diffblock, π/2)
        (r2 - r1)/2
    end
end

n = 4
d = 5
circuit = dispatch!(variational_circuit(n, d),:random)

gatecount(circuit)

h = heisenberg(n)

for i in 1:1000
      grad = my_faithful_grad(h, zero_state(n) => circuit; nshots=100)

      dispatch!(-, circuit, 1e-2 * grad)
      println("Step $i, energy = $(real.(expect(h, zero_state(n)=>circuit)))")
end

using LinearAlgebra
w, _ = eigen(Matrix(mat(h)))
