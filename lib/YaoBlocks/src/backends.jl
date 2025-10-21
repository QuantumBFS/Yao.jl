# Abstract backend type for Yao integration
abstract type AbstractYaoBackend end

# Native Yao backend type
struct YaoBackend <: AbstractYaoBackend end

# Backend type for Pauli path propagation
struct PauliPropagationBackend <: AbstractYaoBackend end

"""
    pauli_to_yao_circuit(n::Int, circ::AbstractVector{Gate}, thetas::AbstractVector)

Convert a circuit represented by a vector of gates and parameters to a Yao circuit representation suited for exact simulation.

# Arguments
- `n::Int`: Number of qubits.
- `circ::AbstractVector{Gate}`: Vector of gates.
- `thetas::AbstractVector`: Vector of parameters.
"""
function pauli_to_yao_circuit(args...)
    error("You must `using PauliPropagation` first to use this feature.")
end

"""
    yao_to_pauli_circuit(circ::ChainBlock)

Convert a Yao circuit to a vector of gates and parameters.

# Arguments
- `circ::ChainBlock`: Yao circuit in the form of a chain of basic gates.
"""
function yao_to_pauli_circuit(args...)
    error("You must `using PauliPropagation` first to use this feature.")
end
