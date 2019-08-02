export AbstractBlock

using YaoBase, YaoArrayRegister, SimpleTraits
import YaoBase: @interface

export nqubits, isreflexive, isunitary, ishermitian

"""
    AbstractBlock

Abstract type for quantum circuit blocks.
"""
abstract type AbstractBlock{N} end

"""
    apply!(register, block)

Apply a block (of quantum circuit) to a quantum register.
"""

@interface function apply!(r::AbstractRegister, b::AbstractBlock)
    _apply_fallback!(r, b)
end

_apply_fallback!(r::AbstractRegister, b::AbstractBlock) = throw(NotImplementedError(:_apply_fallback!, (r, b)))

function _apply_fallback!(r::ArrayReg{B,T}, b::AbstractBlock) where {B,T}
    _check_size(r, b)
    r.state .= mat(T, b) * r.state
    return r
end

"""
    |>(register, blk)

Pipe operator for quantum circuits.

# Example

```julia
julia> ArrayReg(bit"0") |> X |> Y
```

!!! warning

    `|>` is equivalent to [`apply!`](@ref), which means it has side effects. You
    need to copy original register, if you do not want to change it in-place.
"""
Base.:(|>)(r::AbstractRegister, blk::AbstractBlock) = apply!(r, blk)

function apply!(r::AbstractRegister, blk::Function)
    if applicable(blk, nactive(r))
        return apply!(r, blk(nactive(r)))
    else
        error("input function is not applicable, it should take a integer as number of current active qubits.")
    end
end

"""
    occupied_locs(x)

Return a tuple of occupied locations of `x`.
"""
@interface occupied_locs(x::AbstractBlock) = (1:nqubits(x)...,)

"""
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
@interface subblocks(x::AbstractBlock)

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
@interface chsubblocks(x::AbstractBlock, itr)

"""
    applymatrix(g::AbstractBlock) -> Matrix

Transform the apply! function of specific block to dense matrix.
"""
@interface applymatrix(T, g::AbstractBlock) = linop2dense(T, r->statevec(apply!(ArrayReg(r), g)), nqubits(g))
applymatrix(g::AbstractBlock) = applymatrix(ComplexF64, g)
# just use BlockMap maybe? No!

@interface print_block(io::IO, blk::AbstractBlock) = print_block(io, MIME("text/plain"), blk)
print_block(blk::AbstractBlock) = print_block(stdout, blk)
print_block(io::IO, ::MIME"text/plain", blk::AbstractBlock) = summary(io, blk)

# return itself by default
Base.copy(x::AbstractBlock) = x

"""
    mat([T=ComplexF64], blk)

Returns the matrix form of given block.
"""
@interface mat(x::AbstractBlock) = mat(ComplexF64, x)
@interface mat(::Type{T}, x::AbstractBlock) where T

Base.Matrix{T}(x::AbstractBlock) where T = Matrix(mat(T, x))

# YaoBase interface
YaoBase.nqubits(::Type{<:AbstractBlock{N}}) where N = N
YaoBase.nqubits(x::AbstractBlock{N}) where N = nqubits(typeof(x))

# properties
for each_property in [:isunitary, :isreflexive, :ishermitian]
    @eval YaoBase.$each_property(x::AbstractBlock) = $each_property(mat(x))
    @eval YaoBase.$each_property(::Type{T}) where T <: AbstractBlock = $each_property(mat(T))
end

function iscommute_fallback(op1::AbstractBlock{N}, op2::AbstractBlock{N}) where N
    if length(intersect(occupied_locs(op1), occupied_locs(op2))) == 0
        return true
    else
        return iscommute(mat(op1), mat(op2))
    end
end

YaoBase.iscommute(op1::AbstractBlock{N}, op2::AbstractBlock{N}) where N =
    iscommute_fallback(op1, op2)

# parameters
"""
    getiparams(block)

Returns the intrinsic parameters of node `block`, default is an empty tuple.
"""
@interface getiparams(x::AbstractBlock) = ()

"""
    setiparams!(block, itr)
    setiparams!(block, params...)

Set the parameters of `block`.
"""
@interface setiparams!(x::AbstractBlock, args...) = x

setiparams!(x::AbstractBlock, it::Union{Tuple, AbstractArray, Base.Generator}) = setiparams!(x, it...)
setiparams!(x::AbstractBlock, a::Number, xs::Number...) = error("setparams!(x, θ...) is not implemented")
setiparams!(x::AbstractBlock, it::Symbol) = setiparams!(x, render_params(x, it))

"""
    setiparams(f, block, collection)

Set parameters of `block` to the value in `collection` mapped by `f`.
"""
setiparams!(f::Function, x::AbstractBlock, it) = setiparams!(x, map(x->f(x...), zip(getiparams(x), it)))
setiparams!(f::Nothing, x::AbstractBlock, it) = setiparams!(x, it)

"""
    setiparams(f, block, symbol)

Set the parameters to a given symbol, which can be :zero, :random.
"""
setiparams!(f::Function, x::AbstractBlock, it::Symbol) = setiparams!(f, x, render_params(x, it))

"""
    parameters(block)

Returns all the parameters contained in block tree with given root `block`.
"""
@interface parameters(x::AbstractBlock) = parameters!(parameters_eltype(x)[], x)

"""
    parameters!(out, block)

Append all the parameters contained in block tree with given root `block` to
`out`.
"""
@interface parameters!(out, x::AbstractBlock) = prewalk(blk->append!(out, getiparams(blk)), x)

"""
    nparameters(block) -> Int

Return number of parameters in `block`. See also [`nparameters`](@ref).
"""
@interface niparams(x::AbstractBlock) = length(getiparams(x))

@interface function nparameters(x::AbstractBlock)
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
@interface iparams_eltype(x::AbstractBlock) = eltype(getiparams(x))

"""
    parameters_eltype(x)

Return the element type of [`parameters`](@ref).
"""
@interface function parameters_eltype(x::AbstractBlock)
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

@interface function dispatch!(f::Union{Function, Nothing}, x::AbstractBlock, it::Dispatcher)
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
@interface function dispatch!(f::Union{Function, Nothing}, x::AbstractBlock, it)
    dp = Dispatcher(it)
    res = dispatch!(f, x, dp)
    @assert (it isa Symbol || length(it) == dp.loc) "expect $(nparameters(x)) parameters, got $(length(it))"
    return res
end

dispatch!(x::AbstractBlock, it) = dispatch!(nothing, x, it)

"""
    popdispatch!(f, block, list)

Pop the first [`nparameters`](@ref) parameters of list, map them with a function
`f`, then dispatch them to the block tree `block`. See also [`dispatch!`](@ref).
"""
@interface function popdispatch!(f::Function, x::AbstractBlock, list::Vector)
    setiparams!(f, x, (popfirst!(list) for k in 1:niparams(x))...)
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
@interface function popdispatch!(x::AbstractBlock, list::Vector)
    setiparams!(x, (popfirst!(list) for k in 1:niparams(x))...)
    for each in subblocks(x)
        popdispatch!(each, list)
    end
    return x
end

render_params(r::AbstractBlock, params) = params
render_params(r::AbstractBlock, params::Symbol) = render_params(r, Val(params))
render_params(r::AbstractBlock, ::Val{:random}) = (rand() for i=1:niparams(r))
render_params(r::AbstractBlock, ::Val{:zero}) = (zero(iparams_eltype(r)) for i in 1:niparams(r))

"""
    HasParameters{X} <: SimpleTraits.Trait

Trait that block `X` has parameters.
"""
@traitdef HasParameters{X <: AbstractBlock}

@generated function SimpleTraits.trait(::Type{HasParameters{X}}) where X
    hasmethod(parameters, Tuple{X}) ? :(HasParameters{X}) : :(Not{HasParameters{X}})
end


"""
    cache_type(::Type) -> DataType

Return the element type that a [`CacheFragment`](@ref)
will use.
"""
@interface cache_type(::Type{<:AbstractBlock}) = Any

"""
    cache_key(block)

Returns the key that identify the matrix cache of this block. By default, we
use the returns of [`parameters`](@ref) as its key.
"""
@interface cache_key(x::AbstractBlock)

function _check_size(r::AbstractRegister, pb::AbstractBlock{N}) where N
    N == nactive(r) || throw(QubitMismatchError("register size $(nactive(r)) mismatch with block size $N"))
end
