# # Variational Quantum Eigen Solver

using Yao, Yao.AD, Yao.EasyBuild

# number of qubits
n = 4

# depth
d = 5
circuit = dispatch!(variational_circuit(n, d),:random)

gatecount(circuit)

nparameters(circuit)

h = heisenberg(n)

# pick the one you like
# either reverse-mode
# or forward mode
# grad = faithful_grad(h, zero_state(n) => circuit; nshots=100)

for i in 1:1000
      _, grad = expect'(h, zero_state(n) => circuit)
      dispatch!(-, circuit, 1e-2 * grad)
      println("Step $i, energy = $(real.(expect(h, zero_state(n)=>circuit)))")
end

using LinearAlgebra
w, _ = eigen(Matrix(mat(h)))
