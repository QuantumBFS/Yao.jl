"""
    addbit!(register, n::Int) -> register
    addbit!(n::Int) -> Function

addbit the register by n bits in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, addbit bits have higher indices.
If only an integer is provided, then perform lazy evaluation.
"""
@deprecate addbit!(r::AbstractRegister, n::Int) increase!(r, n)
