# Some of the function does not exist in Julia/LinearAlgebra
export isunitary, isreflexive, iscommute, ishermitian

"""
    isunitary(op) -> Bool

check if this operator is a unitary operator.
"""
isunitary(op) = op' * op ≈ IMatrix(size(op, 1))
isunitary(op::Number) = op' * op ≈ one(op)

"""
    isreflexive(op) -> Bool

check if this operator is reflexive.
"""
isreflexive(op) = op * op ≈ IMatrix(size(op, 1))

isreflexive(op::Number) = op * op ≈ one(op)

"""
    ishermitian(op) -> Bool

check if this operator is hermitian.
"""
LinearAlgebra.ishermitian(op) = op' ≈ op

"""
    iscommute(ops...) -> Bool

check if operators are commute.
"""
function iscommute(ops...)
    n = length(ops)
    for i=1:n
        for j=i+1:n
            iscommute(ops[i], ops[j]) || return false
        end
    end
    true
end

iscommute(op1, op2) = op1*op2 ≈ op2*op1
