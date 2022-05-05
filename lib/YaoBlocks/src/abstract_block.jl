# properties
YaoAPI.isunitary(op) = op' * op ≈ IMatrix(size(op, 1))
YaoAPI.isunitary(op::Number) = op' * op ≈ one(op)

YaoAPI.isreflexive(op) = op * op ≈ IMatrix(size(op, 1))
YaoAPI.isreflexive(op::Number) = op * op ≈ one(op)
function YaoAPI.isdiagonal(m::AbstractMatrix)
    return m isa Diagonal || m isa IMatrix
end

"""
    ishermitian(op::AbstractBlock) -> Bool

Returns true if `op` is hermitian.
"""
LinearAlgebra.ishermitian(op) = op' ≈ op

function YaoAPI.iscommute(ops...)
    n = length(ops)
    for i = 1:n
        for j = i+1:n
            iscommute(ops[i], ops[j]) || return false
        end
    end
    true
end

YaoAPI.iscommute(op1, op2) = op1 * op2 ≈ op2 * op1

function YaoAPI.apply!(r::AbstractRegister, b::AbstractBlock)
    _check_size(r, b)
    unsafe_apply!(r, b)
end

function YaoAPI.unsafe_apply!(r::AbstractRegister, b::AbstractBlock)
    _apply_fallback!(r, b)
end

_apply_fallback!(r::AbstractRegister, b::AbstractBlock) =
    throw(NotImplementedError(:_apply_fallback!, (r, b)))

function _apply_fallback!(r::AbstractArrayReg{D,T}, b::AbstractBlock) where {D,T}
    r.state .= mat(T, b) * r.state
    return r
end

"""
    |>(register, circuit) -> register

Apply a quantum circuits to register, which modifies the register directly.

### Example

```julia
julia> arrayreg(bit"0") |> X |> Y
```

!!! warning

    `|>` is equivalent to [`apply!`](@ref), which means it has side effects. You
    need to use [`apply`](@ref) if you do not want to change it in-place.
"""
Base.:(|>)(r::AbstractRegister, blk::AbstractBlock) = apply!(r, blk)

function apply!(r::AbstractRegister, blk::Function)
    if applicable(blk, nactive(r))
        return apply!(r, blk(nactive(r)))
    else
        error(
            "input function is not applicable, it should take a integer as number of current active qubits.",
        )
    end
end

occupied_locs(x::AbstractBlock) = (1:nqudits(x)...,)

"""
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
subblocks(x::AbstractBlock)

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
chsubblocks(x::AbstractBlock, itr)

"""
    applymatrix(g::AbstractBlock) -> Matrix

Transform the apply! function of specific block to dense matrix.
"""
applymatrix(T, g::AbstractBlock) =
    YaoArrayRegister.linop2dense(T, r -> statevec(apply!(ArrayReg(r), g)), nqudits(g))
applymatrix(g::AbstractBlock) = applymatrix(ComplexF64, g)
# just use BlockMap maybe? No!

print_block(io::IO, blk::AbstractBlock) = print_block(io, MIME("text/plain"), blk)
print_block(blk::AbstractBlock) = print_block(stdout, blk)
print_block(io::IO, ::MIME"text/plain", blk::AbstractBlock) = summary(io, blk)

# return itself by default
Base.copy(x::AbstractBlock) = x

function cache_key end

"""
    mat([T=ComplexF64], blk)

Returns the matrix form of given block.
"""
mat(x::AbstractBlock) = mat(promote_type(ComplexF64, parameters_eltype(x)), x)

mat_matchreg(reg::AbstractRegister, x::AbstractBlock) = mat(x)
mat_matchreg(reg::AbstractArrayReg{D,T}, x::AbstractBlock) where {D,T} = mat(T,x)

Base.Matrix{T}(x::AbstractBlock) where {T} = Matrix(mat(T, x))

# YaoAPI interface
YaoAPI.nqubits(block::AbstractBlock{2}) = nqudits(block)
YaoAPI.nlevel(::Type{<:AbstractBlock{D}}) where {D} = D
YaoAPI.nlevel(x::AbstractBlock{D}) where {D} = nlevel(typeof(x))

# properties
# NOTE: isdiagonal does fallback to matrix implementation, because it will be used in eigenbasis, and it is known without knowing the matrix.
for each_property in [:(YaoAPI.isunitary), :(YaoAPI.isreflexive), :(LinearAlgebra.ishermitian)]
    @eval $each_property(x::AbstractBlock) = $each_property(mat(x))
    @eval $each_property(::Type{T}) where {T<:AbstractBlock} =
        $each_property(mat(T))
end

function iscommute_fallback(op1::AbstractBlock{D}, op2::AbstractBlock{D}) where {D}
    _check_block_sizes(op1, op2)
    if length(intersect(occupied_locs(op1), occupied_locs(op2))) == 0
        return true
    else
        return iscommute(mat(op1), mat(op2))
    end
end

YaoAPI.iscommute(op1::AbstractBlock{D}, op2::AbstractBlock{D}) where {D} =
    iscommute_fallback(op1, op2)

# parameters
"""
    getiparams(block)

Returns the intrinsic parameters of node `block`, default is an empty tuple.
"""
getiparams(x::AbstractBlock) = ()

"""
    setiparams!([f], block, itr)
    setiparams!([f], block, params...)

Set the parameters of `block`.
When `f` is provided, set parameters of `block` to the value in `collection` mapped by `f`.
`iter` can be an iterator or a symbol, the symbol can be `:zero`, `:random`.
"""
function setiparams! end

"""
    setiparams([f], block, itr)
    setiparams([f], block, params...)

Set the parameters of `block`, the non-inplace version.
When `f` is provided, set parameters of `block` to the value in `collection` mapped by `f`.
`iter` can be an iterator or a symbol, the symbol can be `:zero`, `:random`.
"""
function setiparams end

for F in [:setiparams!, :setiparams]
    @eval begin
        $F(x::AbstractBlock, args...) =
            niparams(x) == length(args) == 0 ? x :
            throw(NotImplementedError($(QuoteNode(F)), (x, args...)))

        $F(x::AbstractBlock, it::Union{Tuple,AbstractArray,Base.Generator}) = $F(x, it...)
        $F(x::AbstractBlock, a::Number, xs::Number...) =
            error("setparams!(x, θ...) is not implemented")
        $F(x::AbstractBlock, it::Symbol) = $F(x, render_params(x, it))

        $F(f::Function, x::AbstractBlock, it) =
            $F(x, map(x -> f(x...), zip(getiparams(x), it)))
        $F(f::Nothing, x::AbstractBlock, it) = $F(x, it)
        $F(f::Function, x::AbstractBlock, it::Symbol) = $F(f, x, render_params(x, it))
    end
end

"""
    parameters(block)

Returns all the parameters contained in block tree with given root `block`.
"""
parameters(x::AbstractBlock) = parameters!(parameters_eltype(x)[], x)

"""
    parameters!(out, block)

Append all the parameters contained in block tree with given root `block` to
`out`.
"""
function parameters!(out, x::AbstractBlock)
    append!(out, getiparams(x))
    for blk in subblocks(x)
        parameters!(out, blk)
    end
    return out
end

# = prewalk(blk->append!(out, getiparams(blk)), x)

niparams(x::AbstractBlock) = length(getiparams(x))

function nparameters(x::AbstractBlock)
    count = niparams(x)
    for each in subblocks(x)
        count += nparameters(each)
    end
    return count
end

"""
    iparams_eltype(block)

Return the element type of [`getiparams`](@ref).
"""
iparams_eltype(x::AbstractBlock) = eltype(getiparams(x))

"""
    parameters_eltype(x)

Return the element type of [`parameters`](@ref).
"""
function parameters_eltype(x::AbstractBlock)
    T = iparams_eltype(x)
    for each in subblocks(x)
        T = promote_type(T, parameters_eltype(each))
    end
    return T
end

mutable struct Dispatcher{VT}
    params::VT
    loc::Int
end

Dispatcher(params) = Dispatcher(params, 0)

function consume!(d::Dispatcher, n::Int)
    d.loc += n
    d.params[d.loc-n+1:d.loc]
end

function consume!(d::Dispatcher{<:Symbol}, n::Int)
    d.loc += n
    d.params
end

function consume!(d::Dispatcher{<:Number}, n::Int)
    if n == 0
        return ()
    elseif n == 1
        d.loc += n
        return d.params
    else
        error("do not have enough parameters to consume, expect 0, 1, got $n")
    end
end

function dispatch!(f::Union{Function,Nothing}, x::AbstractBlock, it::Dispatcher)
    setiparams!(f, x, consume!(it, niparams(x)))
    for each in subblocks(x)
        dispatch!(f, each, it)
    end
    return x
end

"""
    dispatch!(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`.

!!! note

    it will try to dispatch the parameters in collection first.
"""
function dispatch!(f::Union{Function,Nothing}, x::AbstractBlock, it)
    dp = Dispatcher(it)
    res = dispatch!(f, x, dp)
    @assert (it isa Symbol || length(it) == dp.loc) "expect $(dp.loc) parameters, got $(length(it))"
    return res
end

dispatch!(x::AbstractBlock, it) = dispatch!(nothing, x, it)

"""
    popdispatch!(f, block, list)

Pop the first [`nparameters`](@ref) parameters of list, map them with a function
`f`, then dispatch them to the block tree `block`. See also [`dispatch!`](@ref).
"""
function popdispatch!(f::Function, x::AbstractBlock, list::Vector)
    setiparams!(f, x, (popfirst!(list) for k = 1:niparams(x))...)
    for each in subblocks(x)
        popdispatch!(f, each, list)
    end
    return x
end

"""
    popdispatch!(block, list)

Pop the first [`nparameters`](@ref) parameters of list, then dispatch them to
the block tree `block`. See also [`dispatch!`](@ref).
"""
function popdispatch!(x::AbstractBlock, list::Vector)
    setiparams!(x, (popfirst!(list) for k = 1:niparams(x))...)
    for each in subblocks(x)
        popdispatch!(each, list)
    end
    return x
end

render_params(r::AbstractBlock, params) = params
render_params(r::AbstractBlock, params::Symbol) = render_params(r, Val(params))
render_params(r::AbstractBlock, ::Val{:random}) = (rand() for i = 1:niparams(r))
render_params(r::AbstractBlock, ::Val{:zero}) =
    (zero(iparams_eltype(r)) for i = 1:niparams(r))

"""
    cache_type(::Type) -> DataType

Return the element type that a [`CacheFragment`](@ref)
will use.
"""
cache_type(::Type{<:AbstractBlock}) = Any

"""
    cache_key(block)

Returns the key that identify the matrix cache of this block. By default, we
use the returns of [`parameters`](@ref) as its key.
"""
cache_key(x::AbstractBlock)

function _check_size(r::AbstractRegister{D}, pb::AbstractBlock{D}) where D
    nqudits(pb) == nactive(r) ||
        throw(QubitMismatchError("register size $(nactive(r)) mismatch with block size $(nqudits(pb))"))
    nlevel(r) == nlevel(pb) ||
        throw(QubitMismatchError("register number of level $(nlevel(r)) mismatch with block number of level $(nlevel(pb))"))
end

_check_block_sizes(blocks::AbstractBlock{D}...) where D = _check_block_sizes(blocks)
function _check_block_sizes(blocks::Union{AbstractVector{<:AbstractBlock{D}}, NTuple{N, AbstractBlock{D}} where N}, n=nothing) where D
    if n === nothing
        if length(blocks) == 0
            error("number of blocks can not be 0!")
        else
            n = nqudits(first(blocks))
        end
    end
    for b in blocks
        if nqudits(b) != n
            throw(QubitMismatchError("number of qudits `$(nqudits(b))` does not match the expected value `$(n)`."))
        end
    end
    return n
end

"""
    parameters_range(block)

Return the range of real parameters present in `block`.

!!! note
    It may not be the case that `length(parameters_range(block)) == nparameters(block)`.

# Example

```jldoctest; setup=:(using YaoBlocks)
julia> YaoBlocks.parameters_range(RotationGate(X, 0.1))
1-element Vector{Tuple{Float64, Float64}}:
 (0.0, 6.283185307179586)
```
"""
function parameters_range(block::AbstractBlock)
    T = parameters_eltype(block)
    out = Tuple{T,T}[]
    parameters_range!(out, block)
    out
end

function parameters_range!(out::Vector{Tuple{T,T}}, block::AbstractBlock) where {T}
    np = niparams(block)
    if  np!= 0
        ranges = iparams_range(block)
        @assert length(ranges) == np
        for i=1:np
            push!(out, ranges[i])
        end
    end
    for subblock in subblocks(block)
        parameters_range!(out, subblock)
    end
end

# non-inplace versions
"""
    apply(register, block)

The non-inplace version of applying a block (of quantum circuit) to a quantum register.
Check `apply!` for the faster inplace version.
"""
# overwrite interface, this one avoids one copy
function apply(reg::AbstractRegister{D}, block) where D
    return apply!(copy(reg), block)
end

function generic_dispatch!(f::Union{Function,Nothing}, x::AbstractBlock, it::Dispatcher)
    x = setiparams(f, x, consume!(it, niparams(x)))
    chsubblocks(x, map(subblocks(x)) do each
        generic_dispatch!(f, each, it)
    end)
end

"""
    dispatch(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`, the generic non-inplace version.

!!! note

    it will try to dispatch the parameters in collection first.
"""
function dispatch(f::Union{Function,Nothing}, x::AbstractBlock, it)
    dp = Dispatcher(it)
    res = generic_dispatch!(f, x, dp)
    @assert (it isa Symbol || length(it) == dp.loc) "expect $(dp.loc) parameters, got $(length(it))"
    return res
end

dispatch(x::AbstractBlock, it) = dispatch(nothing, x, it)

BitBasis.basis(b::AbstractBlock{D}) where D = basis(DitStr{D,nqudits(b),Int64})

################## get index ###################

function Base.getindex(b::AbstractBlock{D}, i::DitStr{D,N}, j::DitStr{D,N}) where {D,N}
    T = promote_type(ComplexF64, parameters_eltype(b))
    @assert nqudits(b) == N
    return unsafe_getindex(T, b, buffer(i), buffer(j))
end
function Base.getindex(b::AbstractBlock{D}, ::Colon, j::DitStr{D,N,TI}) where {D,N,TI}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return cleanup(_getindex(T, b, :, j))
end
function Base.getindex(b::AbstractBlock{D}, i::DitStr{D,N,TI}, ::Colon) where {D,N,TI}
    T = promote_type(ComplexF64, parameters_eltype(b))
    return cleanup(_getindex(T, b, i, :))
end
function Base.getindex(b::AbstractBlock{D}, ::Colon, j::EntryTable{DitStr{D,N,TI},T}) where {D,N,TI,T}
    return cleanup(_getindex(b, :, j))
end
function Base.getindex(b::AbstractBlock{D}, i::EntryTable{DitStr{D,N,TI},T}, ::Colon) where {D,N,TI,T}
    return cleanup(_getindex(b, i, :))
end
function _getindex(::Type{T}, b::AbstractBlock{D}, ::Colon, j::DitStr{D,N,TI}) where {T, D,N,TI}
    @assert nqudits(b) == N
    rows, vals = unsafe_getcol(T, b, j)
    return EntryTable(rows, vals)
end
function _getindex(::Type{T}, b::AbstractBlock{D}, i::DitStr{D,N,TI}, ::Colon) where {D,N,TI,T}
    res = _getindex(T, b', :,i)
    conj!(res.amplitudes)
    return res
end
function _getindex(b::AbstractBlock{D}, ::Colon, j::EntryTable{DitStr{D,N,TI},T}) where {D,N,TI,T}
    return merge([(et = _getindex(T,b,:,bs); rmul!(et.amplitudes, amp); et) for (bs, amp) in zip(j.configs, j.amplitudes)]...)
end
function _getindex(b::AbstractBlock{D}, i::EntryTable{DitStr{D,N,TI},T}, ::Colon) where {D,N,TI,T}
    res = _getindex(b',:,i)
    conj!(res.amplitudes)
    return res
end