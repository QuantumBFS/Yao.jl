import LuxurySparse: IMatrix
Base.:≈(x::Number, ::IMatrix{1}) = x ≈ 1
Base.:≈(::IMatrix{1}, x::Number) = x ≈ 1
Base.:(==)(x::Number, ::IMatrix{1}) = x == 1
Base.:(==)(::IMatrix{1}, x::Number) = x == 1

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
