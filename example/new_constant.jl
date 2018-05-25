import QuCircuit: sparse, full, GateType, Gate

sparse(g::Gate{1, GateType{:P}}) = speye(2)
full(g::Gate{1, GateType{:P}}) = eye(2)

Rx(::Type{T}, θ) where T = T

function basic_gate(::Type{T}, S::Symbol, params...) where {T, S}
    basic_gate(T, Val{S}, params...)
end


function basic_gate(::Type{T}, ::Type{Val{:X}}) where T
    print(S)
end

"""
    basic_gate(T, :Rx, theta)

rotation gates
"""
function basic_gate(::Type{T}, ::Type{Val{:Rx}}, theta) where T
end

for NAME in [:X, :Rx]

########################
end


# @doc basic_gate(Complex128, Val{:Rx}, 0.1)
# basic_gate(Complex128, Val{:X})
# Val{:S} <=> Type{Val}
# Complex128 <=> Type{Complex128}


