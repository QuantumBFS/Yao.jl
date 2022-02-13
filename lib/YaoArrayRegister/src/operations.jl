# NOTE: ArrayReg shares some common interfaces with Array

using LinearAlgebra

export isnormalized, normalize!, regadd!, regsub!, regscale!, norm

"""
    isnormalized(r::ArrayReg) -> Bool

Check if the register is normalized.
"""
isnormalized(r::AbstractArrayReg) =
    all(sum(copy(r) |> relax!(to_nactive = nqudits(r)) |> probs, dims = 1) .≈ 1)
isnormalized(r::AdjointArrayReg) = isnormalized(parent(r))

"""
    normalize!(r::AbstractArrayReg)

Normalize the register `r` in-place by its `2`-norm.
"""
function LinearAlgebra.normalize!(r::AbstractArrayReg)
    batch_normalize!(reshape(r.state, :, _asint(nbatch(r))))
    return r
end

LinearAlgebra.normalize!(r::AdjointArrayReg) = (normalize!(parent(r)); r)

LinearAlgebra.norm(r::ArrayReg) = norm(statevec(r))
LinearAlgebra.norm(r::BatchedArrayReg) =
    [norm(view(reshape(r.state, :, nbatch(r)), :, ib)) for ib = 1:nbatch(r)]

# basic arithmatics

# neg
Base.:-(reg::ArrayReg) = ArrayReg(-state(reg))
Base.:-(reg::AdjointArrayReg) = adjoint(-parent(reg))

# +, -
for op in [:+, :-]
    @eval function Base.$op(lhs::AbstractArrayReg{D}, rhs::AbstractArrayReg{D}) where D
        @assert nbatch(lhs) == nbatch(rhs)
        return arrayreg(($op)(state(lhs), state(rhs)); nbatch=nbatch(lhs), nlevel=D)
    end

    @eval function Base.$op(
        lhs::AbstractArrayReg{D,T1,<:Transpose},
        rhs::AbstractArrayReg{D,T2,<:Transpose},
    ) where {D,T1,T2}
        @assert nbatch(lhs) == nbatch(rhs)
        return arrayreg(transpose(($op)(state(lhs).parent, state(rhs).parent)); nbatch=nbatch(lhs), nlevel=D)
    end

    @eval function Base.$op(lhs::AdjointArrayReg{D}, rhs::AdjointArrayReg{D}) where {D}
        r = $op(parent(lhs), parent(rhs))
        return adjoint(r)
    end
end

function regadd!(lhs::AbstractArrayReg{D}, rhs::AbstractArrayReg{D}) where {D}
    @assert nbatch(lhs) == nbatch(rhs)
    lhs.state .+= rhs.state
    lhs
end

function regsub!(lhs::AbstractArrayReg{D}, rhs::AbstractArrayReg{D}) where {D}
    @assert nbatch(lhs) == nbatch(rhs)
    lhs.state .-= rhs.state
    lhs
end

function regadd!(
    lhs::AbstractArrayReg{D,T1,<:Transpose},
    rhs::AbstractArrayReg{D,T2,<:Transpose},
) where {D,T1,T2}
    @assert nbatch(lhs) == nbatch(rhs)
    lhs.state.parent .+= rhs.state.parent
    lhs
end

function regsub!(
    lhs::AbstractArrayReg{D,T1,<:Transpose},
    rhs::AbstractArrayReg{D,T2,<:Transpose},
) where {D,T1,T2}
    @assert nbatch(lhs) == nbatch(rhs)
    lhs.state.parent .-= rhs.state.parent
    lhs
end

function regscale!(reg::AbstractArrayReg{D,T1,<:Transpose}, x) where {D,T1}
    reg.state.parent .*= x
    reg
end

function regscale!(reg::AbstractArrayReg{D}, x) where {D}
    reg.state .*= x
    reg
end

# *, /
for op in [:*, :/]
    @eval function Base.$op(lhs::AbstractArrayReg, rhs::Number)
        arrayreg($op(state(lhs), rhs); nbatch=nbatch(lhs), nlevel=nlevel(lhs))
    end

    @eval function Base.$op(lhs::AdjointArrayReg, rhs::Number)
        r = $op(parent(lhs), rhs')
        return adjoint(r)
    end

    if op == :*
        @eval function Base.$op(lhs::Number, rhs::AbstractArrayReg)
            arrayreg(lhs * state(rhs); nbatch=nbatch(rhs), nlevel=nlevel(rhs))
        end

        @eval function Base.$op(lhs::Number, rhs::AdjointArrayReg)
            r = lhs' * parent(rhs)
            return adjoint(r)
        end
    end
end

function Base.:*(bra::AdjointRegister{D,<:ArrayReg}, ket::ArrayReg{D}) where D
    if nremain(bra) == nremain(ket)
        return dot(relaxedvec(parent(bra)), relaxedvec(ket))
    elseif nremain(bra) == 0 # <s|active> |remain>
        return ArrayReg{D}(state(bra) * state(ket))
    else
        error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| to be fully actived. nactive(bra)/nqudits(bra)=$(nactive(bra))/$(nqudits(bra))",
        )
    end
end

Base.:*(bra::AdjointRegister{D,<:BatchedArrayReg}, ket::BatchedArrayReg{D}) where D = bra .* ket
function Base.:*(
    bra::AdjointRegister{D,<:BatchedArrayReg{D, T1, <:Transpose}},
    ket::BatchedArrayReg{D,T2,<:Transpose},
) where {D,T1,T2}
    if nremain(bra) == nremain(ket) == 0 # all active
        A, C = parent(state(parent(bra))), parent(state(ket))
        res = zeros(eltype(promote_type(T1, T2)), nbatch(ket))
        #return mapreduce((x, y) -> conj(x) * y, +, ; dims=2)
        for j = 1:size(A, 2)
            for i = 1:size(A, 1)
                @inbounds res[i] += conj(A[i, j]) * C[i, j]
            end
        end
        res
    elseif nremain(bra) == 0 # <s|active> |remain>
        bra .* ket
    else
        error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| to be fully actived. nactive(bra)/nqudits(bra)=$(nactive(bra))/$(nqudits(bra))",
        )
    end
end

# broadcast
broadcastable(r::AdjointRegister{D, <:BatchedArrayReg{D}}) where {D} = (each for each in r)

for AT in [:AbstractArrayReg, :AdjointArrayReg]
    @eval function Base.:(==)(lhs::$AT, rhs::$AT)
        nbatch(lhs) == nbatch(rhs) &&
        nlevel(lhs) == nlevel(rhs) &&
        state(lhs) == state(rhs)
    end

    @eval function Base.isapprox(lhs::$AT, rhs::$AT; kw...)
        nbatch(lhs) == nbatch(rhs) &&
        nlevel(lhs) == nlevel(rhs) &&
        isapprox(state(lhs), state(rhs); kw...)
    end
end