using Yao, YaoPlots, YaoExtensions
N = 4
d = 1
ising(nbit, i, j) = rot(kron(nbit, i=>X, j=>X), 0.0)
circuit = dispatch!(variational_circuit(N, d, pair_ring(N), entangler=ising), :zero)

circuit |> vizcircuit(scale=0.7)