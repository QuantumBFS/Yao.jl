using MacroTools: @forward
export AdjointRegister

"""
    AdjointRegister{B, T, RT} <: AbstractRegister{B, T}

Lazy adjoint for a quantum register.
"""
struct AdjointRegister{B,RT<:AbstractRegister{B}} <: AbstractRegister{B}
    parent::RT
end

Base.parent(reg::AdjointRegister) = reg.parent

"""
    adjoint(register) -> register

Lazy adjoint for quantum registers.
"""
Base.adjoint(reg::AbstractRegister) = AdjointRegister(reg)
Base.adjoint(reg::AdjointRegister) = parent(reg)

viewbatch(reg::AdjointRegister, i::Int) = adjoint(viewbatch(parent(reg), i))

@forward AdjointRegister.parent nqubits, nremain, nactive

function Base.summary(io::IO, reg::AdjointRegister{B,RT}) where {B,RT}
    print(io, "adjoint(", summary(reg.parent), ")")
end
