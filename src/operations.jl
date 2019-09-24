# NOTE: ArrayReg shares some common interfaces with Array

using LinearAlgebra

export isnormalized,
    normalize!

"""
    isnormalized(r::ArrayReg) -> Bool

Check if the register is normalized.
"""
isnormalized(r::ArrayReg) = all(sum(copy(r) |> relax!(to_nactive=nqubits(r)) |> probs, dims=1) .≈ 1)
isnormalized(r::AdjointArrayReg) = isnormalized(parent(r))

"""
    normalize!(r::ArrayReg)

Normalize the register `r` in-place by its `2`-norm.
"""
function LinearAlgebra.normalize!(r::ArrayReg{B}) where B
    batch_normalize!(reshape(r.state, :, B))
    return r
end

LinearAlgebra.normalize!(r::AdjointArrayReg) = (normalize!(parent(r)); r)

# basic arithmatics

# neg
Base.:-(reg::ArrayReg) = ArrayReg(-state(reg))
Base.:-(reg::AdjointArrayReg) = adjoint(-parent(reg))

# +, -
for op in [:+, :-]
    @eval function Base.$op(lhs::ArrayReg{B}, rhs::ArrayReg{B}) where B
        return ArrayReg(($op)(state(lhs), state(rhs)))
    end

    @eval function Base.$op(lhs::AdjointArrayReg{B}, rhs::AdjointArrayReg{B}) where B
        r = $op(parent(lhs), parent(rhs))
        return adjoint(r)
    end
end

# *, /
for op in [:*, :/]
    @eval function Base.$op(lhs::RT, rhs::Number) where {B, RT <: ArrayReg{B}}
        ArrayReg{B}($op(state(lhs), rhs))
    end

    @eval function Base.$op(lhs::RT, rhs::Number) where {B, RT <: AdjointArrayReg{B}}
        r = $op(parent(lhs), rhs')
        return adjoint(r)
    end

    if op == :*
        @eval function Base.$op(lhs::Number, rhs::RT) where {B, RT <: ArrayReg{B}}
            ArrayReg{B}(lhs * state(rhs))
        end

        @eval function Base.$op(lhs::Number, rhs::RT) where {B, RT <: AdjointArrayReg{B}}
            r = lhs' * parent(rhs)
            return adjoint(r)
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
