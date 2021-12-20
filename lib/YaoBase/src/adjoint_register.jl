Base.parent(reg::AdjointRegister) = reg.parent

function Base.summary(io::IO, reg::AdjointRegister{B,RT}) where {B,RT}
    return print(io, "adjoint(", summary(reg.parent), ")")
end

"""
    adjoint(register) -> register

Lazy adjoint for quantum registers.
"""
Base.adjoint(reg::AbstractRegister) = AdjointRegister(reg)
Base.adjoint(reg::AdjointRegister) = parent(reg)

viewbatch(reg::AdjointRegister, i::Int) = adjoint(viewbatch(parent(reg), i))

for FUNC in [:nqubits, :nremain, :nactive]
    @eval $FUNC(r::AdjointRegister) = $FUNC(r.parent)
end
