# NOTE: ArrayReg shares some common interfaces with Array

using LinearAlgebra

export isnormalized,
    normalize!

"""
    isnormalized(r::ArrayReg) -> Bool

Check if the register is normalized.
"""
isnormalized(r::ArrayReg) = all(sum(copy(r) |> relax!(to_nactive=nqubits(r)) |> probs, dims=1) .≈ 1)

"""
    normalize!(r::ArrayReg)

Normalize the register `r` in-place by its `2`-norm.
"""
function LinearAlgebra.normalize!(r::ArrayReg{B}) where B
    batch_normalize!(reshape(r.state, :, B))
    return r
end

# basic arithmatics

# neg
Base.:-(reg::ArrayReg) = ArrayReg(-state(reg))

# +, -
for op in [:+, :-]
    @eval function Base.$op(lhs::ArrayReg{B}, rhs::ArrayReg{B}) where B
        return ArrayReg(($op)(state(lhs), state(rhs)))
    end
end

# *, /
for op in [:*, :/]
    @eval function Base.$op(lhs::RT, rhs::Number) where {B, RT <: ArrayReg{B}}
        ArrayReg{B}($op(state(lhs), rhs))
    end

    if op == :*
        @eval function Base.$op(lhs::Number, rhs::RT) where {B, RT <: ArrayReg{B}}
            ArrayReg{B}(($op)(lhs, state(rhs)))
        end
    end
end

for op in [:(==), :≈]
    for AT in [:ArrayReg, :AdjointArrayReg]
        @eval function Base.$op(lhs::$AT, rhs::$AT)
            ($op)(state(lhs), state(rhs))
        end
    end
end

Base.:*(bra::AdjointArrayReg{1}, ket::ArrayReg{1}) = dot(state(parent(bra)), state(ket))
Base.:*(bra::AdjointArrayReg{B}, ket::ArrayReg{B}) where B = bra .* ket

# broadcast
broadcastable(r::ArrayRegOrAdjointArrayReg{1}) = Ref(r)
broadcastable(r::ArrayRegOrAdjointArrayReg{B}) where B = (each for each in r)
