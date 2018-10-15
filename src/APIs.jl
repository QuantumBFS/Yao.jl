export nqubits, nactive, reorder, invorder

function nqubits end
function nactive end
function reorder end

"""
    invorder(reg) -> reg

Inverse the order of qubits.
"""
invorder(v) = reorder(v, collect(nqubits(v):-1:1))
