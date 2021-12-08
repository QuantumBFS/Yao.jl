# NOTE: ArrayReg shares some common interfaces with Array

using LinearAlgebra

export isnormalized, normalize!, regadd!, regsub!, regscale!, norm

"""
    isnormalized(r::ArrayReg) -> Bool

Check if the register is normalized.
"""
function isnormalized(r::ArrayReg)
    return all(sum(probs(relax!(; to_nactive=nqubits(r))(copy(r))); dims=1) .≈ 1)
end
isnormalized(r::AdjointArrayReg) = isnormalized(parent(r))

"""
    normalize!(r::ArrayReg)

Normalize the register `r` in-place by its `2`-norm.
"""
function LinearAlgebra.normalize!(r::ArrayReg{B}) where {B}
    batch_normalize!(reshape(r.state, :, B))
    return r
end

LinearAlgebra.normalize!(r::AdjointArrayReg) = (normalize!(parent(r)); r)

LinearAlgebra.norm(r::ArrayReg{1}) = norm(statevec(r))
function LinearAlgebra.norm(r::ArrayReg{B}) where {B}
    return [norm(view(reshape(r.state, :, B), :, ib)) for ib in 1:B]
end

# basic arithmatics

# neg
Base.:-(reg::ArrayReg) = ArrayReg(-state(reg))
Base.:-(reg::AdjointArrayReg) = adjoint(-parent(reg))

# +, -
for op in [:+, :-]
    @eval function Base.$op(lhs::ArrayReg{B}, rhs::ArrayReg{B}) where {B}
        return ArrayReg(($op)(state(lhs), state(rhs)))
    end

    @eval function Base.$op(
        lhs::ArrayReg{B,T1,<:Transpose}, rhs::ArrayReg{B,T2,<:Transpose}
    ) where {B,T1,T2}
        return ArrayReg(transpose(($op)(state(lhs).parent, state(rhs).parent)))
    end

    @eval function Base.$op(lhs::AdjointArrayReg{B}, rhs::AdjointArrayReg{B}) where {B}
        r = $op(parent(lhs), parent(rhs))
        return adjoint(r)
    end
end

function regadd!(lhs::ArrayReg{B}, rhs::ArrayReg{B}) where {B}
    lhs.state .+= rhs.state
    return lhs
end

function regsub!(lhs::ArrayReg{B}, rhs::ArrayReg{B}) where {B}
    lhs.state .-= rhs.state
    return lhs
end

function regadd!(
    lhs::ArrayReg{B,T1,<:Transpose}, rhs::ArrayReg{B,T2,<:Transpose}
) where {B,T1,T2}
    lhs.state.parent .+= rhs.state.parent
    return lhs
end

function regsub!(
    lhs::ArrayReg{B,T1,<:Transpose}, rhs::ArrayReg{B,T2,<:Transpose}
) where {B,T1,T2}
    lhs.state.parent .-= rhs.state.parent
    return lhs
end

function regscale!(reg::ArrayReg{B,T1,<:Transpose}, x) where {B,T1}
    reg.state.parent .*= x
    return reg
end

function regscale!(reg::ArrayReg{B}, x) where {B,T1}
    reg.state .*= x
    return reg
end

# *, /
for op in [:*, :/]
    @eval function Base.$op(lhs::RT, rhs::Number) where {B,RT<:ArrayReg{B}}
        return ArrayReg{B}($op(state(lhs), rhs))
    end

    @eval function Base.$op(lhs::RT, rhs::Number) where {B,RT<:AdjointArrayReg{B}}
        r = $op(parent(lhs), rhs')
        return adjoint(r)
    end

    if op == :*
        @eval function Base.$op(lhs::Number, rhs::RT) where {B,RT<:ArrayReg{B}}
            return ArrayReg{B}(lhs * state(rhs))
        end

        @eval function Base.$op(lhs::Number, rhs::RT) where {B,RT<:AdjointArrayReg{B}}
            r = lhs' * parent(rhs)
            return adjoint(r)
        end
    end
end

for AT in [:ArrayReg, :AdjointArrayReg]
    @eval function Base.:(==)(lhs::$AT, rhs::$AT)
        return state(lhs) == state(rhs)
    end

    @eval function Base.isapprox(lhs::$AT, rhs::$AT; kw...)
        return isapprox(state(lhs), state(rhs); kw...)
    end
end

function Base.:*(bra::AdjointArrayReg{1}, ket::ArrayReg{1})
    if nremain(bra) == nremain(ket)
        return dot(relaxedvec(parent(bra)), relaxedvec(ket))
    elseif nremain(bra) == 0 # <s|active> |remain>
        return ArrayReg{1}(state(bra) * state(ket))
    else
        error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| to be fully actived. nactive(bra)/nqubits(bra)=$(nactive(bra))/$(nqubits(bra))",
        )
    end
end

Base.:*(bra::AdjointArrayReg{B}, ket::ArrayReg{B}) where {B} = bra .* ket
function Base.:*(
    bra::AdjointArrayReg{B,T1,<:Transpose}, ket::ArrayReg{B,T2,<:Transpose}
) where {B,T1,T2}
    if nremain(bra) == nremain(ket) == 0 # all active
        A, C = parent(state(parent(bra))), parent(state(ket))
        res = zeros(eltype(promote_type(T1, T2)), B)
        #return mapreduce((x, y) -> conj(x) * y, +, ; dims=2)
        for j in 1:size(A, 2)
            for i in 1:size(A, 1)
                @inbounds res[i] += conj(A[i, j]) * C[i, j]
            end
        end
        res
    elseif nremain(bra) == 0 # <s|active> |remain>
        bra .* ket
    else
        error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| to be fully actived. nactive(bra)/nqubits(bra)=$(nactive(bra))/$(nqubits(bra))",
        )
    end
end

# broadcast
broadcastable(r::ArrayRegOrAdjointArrayReg{1}) = Ref(r)
broadcastable(r::ArrayRegOrAdjointArrayReg{B}) where {B} = (each for each in r)
