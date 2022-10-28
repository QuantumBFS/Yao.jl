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

"""
$TYPEDSIGNATURES

The overlap between `ket` and `bra`, which is only defined for two fully activated equal sized registers.
It is only slightly different from [`inner_product`](@ref) in that it always returns a complex number.

### Examples
```jldoctest; setup=:(using YaoArrayRegister)
julia> reg1 = ghz_state(3);

julia> reg2 = uniform_state(3);

julia> reg1' * reg2
0.5 + 0.0im
```
"""
function Base.:*(bra::AdjointRegister{D,<:ArrayReg}, ket::ArrayReg{D})::Number where D
    # check the register sizes
    nqudits(bra) == nqudits(ket) && nremain(bra) == nremain(ket) || error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| and |ket⟩ to have the same size. Got nactive(bra)/nqudits(bra)=$(nactive(bra))/$(nqudits(bra)), nactive(ket)/nqudits(ket)=$(nactive(ket))/$(nqudits(ket))",
        )
    return dot(relaxedvec(parent(bra)), relaxedvec(ket))
end

Base.:*(bra::AdjointRegister{D,<:BatchedArrayReg{D}}, ket::BatchedArrayReg{D}) where D = bra .* ket
function Base.:*(
    bra::AdjointRegister{D,<:BatchedArrayReg{D, T1, <:Transpose}},
    ket::BatchedArrayReg{D,T2,<:Transpose},
) where {D,T1,T2}
    nqudits(bra) == nqudits(ket) && nremain(bra) == nremain(ket) && nbatch(bra) == nbatch(ket) || error(
            "partially contract ⟨bra|ket⟩ is not supported, expect ⟨bra| and |ket⟩ to have the same size. Got nactive(bra)/nqudits(bra)/nbatch(bra)=$(nactive(bra))/$(nqudits(bra))/$(nbatch(bra)), nactive(ket)/nqudits(ket)=$(nactive(ket))/$(nqudits(ket))/$(nbatch(ket))",
        )
    A, C = parent(state(parent(bra))), parent(state(ket))
    res = zeros(eltype(promote_type(T1, T2)), nbatch(ket))
    for j = 1:size(A, 2)
        for i = 1:size(A, 1)
            @inbounds res[i] += conj(A[i, j]) * C[i, j]
        end
    end
    res
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

Returns true if qudits at `locs` are seperable from the rest qudits.
A state ``|ψ⟩`` is separable if
```math
|\\psi\\rangle = |a\\rangle \\otimes |b\\rangle
```
where ``|a⟩`` is defined on the state space at `locs`.

### Examples
```jldoctest; setup=:(using YaoArrayRegister)
julia> isseparable(product_state(bit"01100"), 1:2)
true

julia> isseparable(ghz_state(5), 1:2)
false
```
"""
function isseparable(reg::AbstractArrayReg{D}, locs) where D
    n = nactive(reg)
    p = length(locs)
    r = reorder!(copy(reg), sortperm([locs..., setdiff(1:n, locs)...]))
    if reg isa BatchedArrayReg
        return all(x->rank(reshape(x.state, D^p, :)) == 1, r)
    else
        return rank(reshape(r.state, D^p, :)) == 1
    end
end

"""
$(TYPEDSIGNATURES)

Remove qubits that are not entangled with the rest qudits safely.
i.e. `isseparable(reg, locs)` must return true.

### Examples
```jldoctest; setup=:(using YaoArrayRegister)
julia> reg = join(ghz_state(3), ghz_state(2));

julia> safe_remove!(copy(reg), 1:2)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 3/3
    nlevel: 2

julia> safe_remove!(copy(reg), 1:3)
ERROR: Qubits at locations 1:3 are entangled with the rest qubits.
[...]
```
"""
function safe_remove!(reg::AbstractArrayReg, locs)
    if isseparable(reg, locs)
        measure!(RemoveMeasured(), reg, locs)
        return reg
    else
        error("Qubits at locations $(locs) are entangled with the rest qubits.")
    end
end