export nqubits, nactive, isunitary, isreflexive, nparameters, datatype, mat, dispatch!, nbatch

# All exported methods and types docstring should be defined here.

"""
    nqubits(m::AbstractRegister) -> Int
number of qubits in a register,

    nqubits(m::AbstractBlock) -> Int
number of qubits applied for a block,

    nqubits(m::AbstractArray) -> Int
size of the first dimension of an array, in 2^nqubits.
"""
function nqubits end
function nactive end
function datatype end
