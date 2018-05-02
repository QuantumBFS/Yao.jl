# CNOT is not implemented yet
# A IBM Quantum Experience Demo:
# https://quantumexperience.ng.bluemix.net/proxy/tutorial/full-user-guide/003-Multiple_Qubits_Gates_and_Entangled_States/060-GHZ_States.html

using QuCircuit

const num_qubit = 3

circuit = chain(
    num_qubit, # total qubits
    kron(gate(H), gate(H), gate(X)),
    focus(2, 3),
    gate(CNOT),
    focus(1, 3),
    gate(CNOT),
    focus(1:3),
    kron(gate(H), gate(H), gate(H)),
)

reg = zero_state(3)
apply!(reg, circuit)
print(reg)
