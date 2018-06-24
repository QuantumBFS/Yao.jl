"""
    isunitary(op) -> Bool

check if this operator is a unitary operator.
"""
isunitary(op) = op' * op ≈ IMatrix(size(op, 1))

"""
    isreflexive(op) -> Bool

check if this operator is reflexive.
"""
isreflexive(op) = op * op ≈ IMatrix(size(op, 1))

"""
    ishermitian(op) -> Bool

check if this operator is hermitian.
"""
ishermitian(op) = op' ≈ op

isunitary(m::Module)= m == Yao
