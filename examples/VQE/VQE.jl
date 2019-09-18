# # [Variational Quantum Eigensolver](@id VQE)

# ## References
# * [A variational eigenvalue solver on a quantum processor](https://arxiv.org/abs/1304.3061)
# * [Variational Quantum Eigensolver with Fewer Qubits](https://arxiv.org/abs/1902.02663)

# ## Define a hamiltonian

# construct a 5-site heisenberg hamiltonian

using Yao, YaoExtensions

N = 5
hami = heisenberg(N)

# The ground state can be obtained by a sparse matrix ground state solver.
# The high performance `mat` function in `Yao.jl` makes computation time lower than `10s`
# to construct a `20` site Heisenberg hamltonian
using KrylovKit: eigsolve

function ed_groundstate(h::AbstractBlock)
    E, V = eigsolve(h |> mat, 1, :SR, ishermitian=true)
    E[1], V[1]
end

ed_groundstate(hami)

# Here we use the `heisenberg` hamiltonian that defined in [`YaoExtensions.jl`](https://github.com/QuantumBFS/YaoExtensions.jl),
# for tutorial purpose, we pasted the code for construction here.
# ```julia
# function heisenberg(nbit::Int; periodic::Bool=true)
#    sx = i->put(nbit, i=>X)
#    sy = i->put(nbit, i=>Y)
#    sz = i->put(nbit, i=>Z)
#    map(1:(periodic ? nbit : nbit-1)) do i
#        j=i%nbit+1
#        sx(i)*sx(j)+sy(i)*sy(j)+sz(i)*sz(j)
#     end |> sum
# end
# ```

# ## Define an ansatz
# As an ansatz, we use the canonical circuit for demonstration [`variational_circuit`](@ref YaoExtensions.variational_circuit)
# defined in [`YaoExtensions.jl`](https://github.com/QuantumBFS/YaoExtensions.jl).
c = variational_circuit(N)
dispatch!(c, :random)

# ## Run
# Use the [`Adam`](@ref) optimizer for parameter optimization,
# we provide a poorman's implementation in `QuAlgorithmZoo`
using QuAlgorithmZoo: Adam, update!

optimizer = Adam(lr=0.01)
params = parameters(c)
niter = 100

for i = 1:niter
    ## `expect'` gives the gradient of an observable.
    grad_input, grad_params = expect'(hami, zero_state(N) => c)

    ## feed the gradients into the circuit.
    dispatch!(c, update!(params, grad_params, optimizer))
    println("Step $i, Energy = $(expect(hami, zero_state(N) |> c))")
end
