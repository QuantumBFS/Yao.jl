# NOTE: ArrayReg shares some common interfaces with Array
"""
    isnormalized(r::ArrayReg) -> Bool

Returns true if the register `r` is normalized.
"""
isnormalized(r::AbstractArrayReg) =
    all(sum(copy(r) |> relax!(to_nactive = nqudits(r)) |> probs, dims = 1) .≈ 1)
isnormalized(r::AdjointRegister) = isnormalized(parent(r))

"""
    normalize!(r::AbstractArrayReg)

Normalize the register `r` by its 2-norm.
It changes the register directly.

### Examples

The following code creates a normalized GHZ state.

```julia
julia> reg = product_state(bit"000") + product_state(bit"111");

julia> norm(reg)
1.4142135623730951

julia> isnormalized(reg)
false

julia> normalize!(reg);

julia> isnormalized(reg)
true
```
"""
function LinearAlgebra.normalize!(r::AbstractArrayReg)
    batch_normalize!(reshape(r.state, :, _asint(nbatch(r))))
    return r
end

LinearAlgebra.normalize!(r::AdjointRegister) = (normalize!(parent(r)); r)

LinearAlgebra.norm(r::ArrayReg) = norm(statevec(r))
LinearAlgebra.norm(r::BatchedArrayReg) =
    [norm(view(reshape(r.state, :, nbatch(r)), :, ib)) for ib = 1:nbatch(r)]

# basic arithmatics

# neg
Base.:-(reg::Union{AbstractArrayReg{D},DensityMatrix{D}}) where D = chstate(reg, -state(reg))
Base.:-(reg::AdjointRegister) = adjoint(-parent(reg))

# +, -
for op in [:+, :-]
    @eval function Base.$op(lhs::AbstractArrayReg{D}, rhs::AbstractArrayReg{D}) where D
        @assert nbatch(lhs) == nbatch(rhs)
        return chstate(lhs, ($op)(state(lhs), state(rhs)))
    end
    @eval function Base.$op(lhs::DensityMatrix{D}, rhs::DensityMatrix{D}) where D
        @assert nbatch(lhs) == nbatch(rhs)
        return chstate(lhs, ($op)(state(lhs), state(rhs)))
    end
    @eval function Base.$op(
        lhs::AbstractArrayReg{D,T1,<:Transpose},
        rhs::AbstractArrayReg{D,T2,<:Transpose},
    ) where {D,T1,T2}
        @assert nbatch(lhs) == nbatch(rhs)
        return chstate(lhs, transpose(($op)(state(lhs).parent, state(rhs).parent)))
    end

    @eval function Base.$op(lhs::AdjointRegister{D}, rhs::AdjointRegister{D}) where {D}
        r = $op(parent(lhs), parent(rhs))
        return adjoint(r)
    end
end

"""
    regadd!(target, source)

Inplace version of `+` that accumulates `source` to `target`.
"""
function regadd! end

"""
    regsub!(target, source)

Inplace version of `-` that subtract `source` from `target`.
"""
function regsub! end

"""
    regscale!(target, x)

Inplace version of multiplying a scalar `x` to target.
"""
function regscale! end

for T in [:ArrayReg, :DensityMatrix, :BatchedArrayReg]
    @eval function regadd!(lhs::$T{D}, rhs::$T{D}) where {D}
        @assert nbatch(lhs) == nbatch(rhs)
        lhs.state .+= rhs.state
        lhs
    end
    @eval function regsub!(lhs::$T{D}, rhs::$T{D}) where {D}
        @assert nbatch(lhs) == nbatch(rhs)
        lhs.state .-= rhs.state
        lhs
    end
    @eval function regscale!(reg::$T{D}, x) where {D}
        reg.state .*= x
        reg
    end
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

# *, /
for op in [:*, :/]
    @eval function Base.$op(lhs::Union{AbstractArrayReg,DensityMatrix}, rhs::Number)
        chstate(lhs, $op(state(lhs), rhs))
    end

    @eval function Base.$op(lhs::AdjointRegister, rhs::Number)
        r = $op(parent(lhs), rhs')
        return adjoint(r)
    end

    if op == :*
        @eval function Base.$op(lhs::Number, rhs::Union{AbstractArrayReg,DensityMatrix})
            chstate(rhs, lhs * state(rhs))
        end

        @eval function Base.$op(lhs::Number, rhs::AdjointRegister)
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

Base.:*(bra::AdjointRegister{D,<:BatchedArrayReg{D}}, ket::BatchedArrayReg{D}) where D = bra .* ket
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

function Base.:(==)(lhs::AbstractArrayReg, rhs::AbstractArrayReg)
    nbatch(lhs) == nbatch(rhs) &&
    nlevel(lhs) == nlevel(rhs) &&
    state(lhs) == state(rhs)
end

function Base.isapprox(lhs::AbstractArrayReg, rhs::AbstractArrayReg; kw...)
    nbatch(lhs) == nbatch(rhs) &&
    nlevel(lhs) == nlevel(rhs) &&
    isapprox(state(lhs), state(rhs); kw...)
end

Base.:(==)(lhs::AdjointRegister, rhs::AdjointRegister) = parent(lhs) == parent(rhs)
Base.isapprox(lhs::AdjointRegister, rhs::AdjointRegister; kw...) = isapprox(parent(lhs), parent(rhs); kw...)

"""
$(TYPEDSIGNATURES)

Returns true if the `parts` are seperable from the rest parts.
i.e. let `B` be the specified part and `A` be the rest part.
The register can be represented as `A ⊗ B`.
"""
function isseparable(reg::AbstractArrayReg{D}, parts) where D
    n = nactive(reg)
    p = length(parts)
    r = reorder!(copy(reg), sortperm([parts..., setdiff(1:n, parts)...]))
    if reg isa BatchedArrayReg
        return all(x->rank(reshape(x.state, D^p, :)) == 1, r)
    else
        return rank(reshape(r.state, D^p, :)) == 1
    end
end

"""
$(TYPEDSIGNATURES)

Remove a qubit not entangled with the rest parts safely.
"""
function safe_remove!(reg::AbstractArrayReg, parts)
    if isseparable(reg, parts)
        measure!(RemoveMeasured(), reg, parts)
        return reg
    else
        error("Qubits at locations $(parts) are entangled with the rest qubits.")
    end
end