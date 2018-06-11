export nqubits, nactive

"""
    nqubits(m::AbstractRegister) -> Int
Returns number of qubits in a register,

    nqubits(m::AbstractBlock) -> Int
Returns number of qubits applied for a block,

    nqubits(m::AbstractArray) -> Int
Returns size of the first dimension of an array, in 2^nqubits.
"""
function nqubits end

"""
    nactive(x) -> Int

Returns number of active qubits
"""
function nactive end
