# joining two registers
⊗(reg::AbstractRegister, reg2::AbstractRegister) = join(reg, reg2)
⊗(A::AbstractArray, B::AbstractArray) = kron(A, B)

# apply!
using LinearAlgebra: Adjoint
Base.:(|>)(reg::AbstractRegister, circuit::Union{AbstractBlock, Adjoint{<:Any, <:AbstractBlock}}) = apply!(reg, circuit)
