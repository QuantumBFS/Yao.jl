using MacroTools: @forward

struct AdjointRegister{B, T, RT <: AbstractRegister{B, T}} <: AbstractRegister{B, T}
    parent::RT
end

Base.adjoint(reg::AbstractRegister) = AdjointRegister(reg)
Base.adjoint(reg::AdjointRegister) = reg.parent
Base.parent(reg::AdjointRegister) = reg.parent

viewbatch(reg::AdjointRegister, i::Int) = adjoint(viewbatch(parent(reg), i))

@forward AdjointRegister.parent nqubits, nremain, nactive

function Base.summary(io::IO, reg::AdjointRegister{B, T, RT}) where {B, T, RT}
    print(io, "adjoint(", summary(reg.parent), ")")
end
