################### ConjRegister ##################
const ConjRegister{B, T, RT} = Adjoint{Any, RT} where RT<:AbstractRegister{B, T}

Base.adjoint(reg::RT) where RT<:AbstractRegister = Adjoint{Any, RT}(reg)

function Base.show(io::IO, c::ConjRegister)
    print(io, "$(parent(c)) [†]")
end

#### Abstract Register Interfaces
state(bra::ConjRegister) = Adjoint(parent(bra) |> state)
viewbatch(reg::ConjRegister, ind::Int) = viewbatch(parent(reg), ind)'

@forward ConjRegister.parent nqubits, nactive, nremain, nbatch, length

register(raw::Adjoint{<:Any, <:AbstractMatrix}; B=size(raw,1)) = register(raw |> parent, B=B)'
