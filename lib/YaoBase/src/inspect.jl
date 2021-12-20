isunitary(op) = op' * op ≈ IMatrix(size(op, 1))
isunitary(op::Number) = op' * op ≈ one(op)

isreflexive(op) = op * op ≈ IMatrix(size(op, 1))
isreflexive(op::Number) = op * op ≈ one(op)

"""
    ishermitian(op) -> Bool

check if this operator is hermitian.
"""
LinearAlgebra.ishermitian(op) = op' ≈ op

function iscommute(ops...)
    n = length(ops)
    for i in 1:n
        for j in (i + 1):n
            iscommute(ops[i], ops[j]) || return false
        end
    end
    return true
end

iscommute(op1, op2) = op1 * op2 ≈ op2 * op1
