mutable struct GPURegister{B, T} <: AbstractRegister{B, T}
    state
    nactive::Int
    address::Vector{Int}
end
