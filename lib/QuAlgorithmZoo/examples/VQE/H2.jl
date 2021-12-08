using Yao
using YaoExtensions

# arXiv: 1704.05018, table S2
function hydrogen_hamiltonian()
    Z1 = put(2,1=>Z)
    Z2 = put(2,2=>Z)
    X1 = put(2,1=>X)
    X2 = put(2,2=>X)
    0.011280*Z1*Z2 + 0.397936*Z1 + 0.397936*Z2 + 0.180931*X1*X2
end

using Flux: Optimise
function train!(circ, hamiltonian; optimizer, niter::Int=100)
     params = parameters(circ)
     dispatch!(circ, :random)
     for i=1:niter
         _, grad = expect'(hamiltonian, zero_state(nqubits(circ)) => circ)
         Optimise.update!(optimizer, params, grad)
         dispatch!(circ, params)
         println("Energy = $(expect(hamiltonian, zero_state(nqubits(hamiltonian)) |> circ) |> real)")
     end
     return expect(hamiltonian, zero_state(nqubits(hamiltonian)) |> circ)
end

h = hydrogen_hamiltonian()
c = variational_circuit(2)
emin_vqe = train!(c, h; optimizer=Optimise.ADAM(0.1))

using LinearAlgebra
emin = eigvals(Matrix(mat(h)))[1]
@assert isapprox(emin, emin, atol=1e-1)
