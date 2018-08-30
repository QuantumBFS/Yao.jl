# joining two registers
⊗(reg::AbstractRegister, reg2::AbstractRegister) = join(reg, reg2)
⊗(A::AbstractArray, B::AbstractArray) = kron(A, B)

# apply!
Base.:(|>)(reg::AbstractRegister, circuit::AbstractBlock) = apply!(reg, circuit)
