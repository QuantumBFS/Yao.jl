mutable struct MPSRegister{B, T}
    state
    nactive::Int
    address::Vector{Int}
end
