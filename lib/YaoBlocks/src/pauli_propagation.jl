"""
    paulipropagation2yao(n::Int, circ::AbstractVector{Gate}, thetas::AbstractVector)
    paulipropagation2yao(pc::PauliCircuit)

Convert a Pauli propagation circuit to a Yao circuit. You must `using PauliPropagation` before using this function.

# Arguments
- `n::Int`: Number of qubits.
- `circ::AbstractVector{Gate}`: Pauli propagation circuit.
- `thetas::AbstractVector`: Vector of parameters.

Or:
- `pc::PauliCircuit`: A PauliCircuit intermediate representation.
"""
function paulipropagation2yao(args...)
    error("You must `using PauliPropagation` first to use this feature.")
end

"""
    yao2paulipropagation(circ::ChainBlock; observable)

Convert a Yao circuit to a Pauli propagation circuit representation. You must `using PauliPropagation` before using this function.

# Arguments
- `circ::ChainBlock`: Yao circuit in the form of a chain of basic gates.

# Keyword Arguments
- `observable`: A Yao block specifying the observable to measure (required). Must be a sum of Pauli strings, e.g. `kron(5, 2=>X, 3=>X) + 2.0 * kron(5, 1=>Z)`. Will be converted to a `PauliSum`.

# Returns
- `PauliPropagationCircuit`: An intermediate representation that can be evaluated with `propagate(pc)`.
"""
function yao2paulipropagation(args...; kwargs...)
    error("You must `using PauliPropagation` first to use this feature.")
end
