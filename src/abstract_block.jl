export AbstractBlock

using YaoBase, SimpleTraits
import YaoBase: @interface

export nqubits, datatype, isreflexive, isunitary, ishermitian

"""
    AbstractBlock

Abstract type for quantum circuit blocks.
"""
abstract type AbstractBlock{N, T} end

"""
    apply!(register, block)

Apply a block (of quantum circuit) to a quantum register.
"""
@interface function apply!(r::ArrayReg, b::AbstractBlock)
    r.state = mat(b) * r.state
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

Return an iterator of occupied locations of `x`.
"""
@interface occupied_locs(x::AbstractBlock) = 1:nqubits(x)

"""
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
@interface subblocks(x::AbstractBlock) = ()

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
@interface chsubblocks(x::AbstractBlock, itr)

"""
    applymatrix(g::AbstractBlock) -> Matrix

Transform the apply! function of specific block to dense matrix.
"""
@interface applymatrix(g::AbstractBlock) = linop2dense(r->statevec(apply!(ArrayReg(r), g)), nqubits(g))

@interface print_block(io::IO, blk::AbstractBlock) = print_block(io, MIME("text/plain"), blk)
print_block(blk::AbstractBlock) = print_block(stdout, blk)
print_block(io::IO, ::MIME"text/plain", blk::AbstractBlock) = summary(io, blk)

# return itself by default
Base.copy(x::AbstractBlock) = x

"""
    mat(blk)

Returns the matrix form of given block.
"""
@interface mat(::AbstractBlock)

# YaoBase interface
YaoBase.nqubits(::Type{<:AbstractBlock{N}}) where N = N
YaoBase.nqubits(x::AbstractBlock{N}) where N = nqubits(typeof(x))
YaoBase.datatype(x::AbstractBlock{N, T}) where {N, T} = T
YaoBase.datatype(::Type{<:AbstractBlock{N, T}}) where {N, T} = T

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

setiparams!(x::AbstractBlock, it) = setiparams!(x, it...)
setiparams!(x::AbstractBlock, it::Symbol) = setiparams!(x, render_params(x, it))

"""
    setiparams(f, block, collection)

Set parameters of `block` to the value in `collection` mapped by `f`.
"""
setiparams!(f::Function, x::AbstractBlock, it) = setiparams!(x, map(f, it))

"""
    setiparams(f, block, symbol)

Set the parameters to a given symbol, which can be :zero, :random.
"""
setiparams!(f::Function, x::AbstractBlock, it::Symbol) = setiparams!(f, x, render_params(x, it))

"""
    parameters(block)

Returns all the parameters contained in block tree with given root `block`.
"""
@interface parameters(x::AbstractBlock) = parameters!(allparams_eltype(x)[], x)

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
    params_eltype(block)

Return the element type of [`getiparams`](@ref).
"""
@interface params_eltype(x::AbstractBlock) = eltype(getiparams(x))

"""
    allparams_eltype(x)

Return the element type of [`parameters`](@ref).
"""
@interface function allparams_eltype(x::AbstractBlock)
    T = params_eltype(x)
    for each in subblocks(x)
        T = promote_type(T, params_eltype(each))
    end
    return T
end

"""
    dispatch!(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`.
"""
@interface function dispatch!(f::Function, x::AbstractBlock, it)
    @assert length(it) == nparameters(x) "expect $(nparameters(x)) parameters, got $(length(it))"
    setiparams!(f, x, Iterators.take(it, nparameters(x)))
    it = Iterators.drop(it, nparameters(x))
    for each in subblocks(x)
        dispatch!(f, each, it)
    end
    return x
end

function dispatch!(f::Function, x::AbstractBlock, it::Symbol)
    setiparams!(f, x, it)
    for each in subblocks(x)
        dispatch!(f, each, it)
    end
    return x
end

dispatch!(x::AbstractBlock, it) = dispatch!(identity, x, it)

"""
    popdispatch!(f, block, list)

Pop the first [`nparameters`](@ref) parameters of list, map them with a function
`f`, then dispatch them to the block tree `block`. See also [`dispatch!`](@ref).
"""
@interface function popdispatch!(f::Function, x::AbstractBlock, list::Vector)
    setiparams!(x, ntuple(()->f(popfirst!(list)), nparameters(x)))
    for each in subblocks(x)
        popdispatch!(x, list)
    end
    return x
end

"""
    popdispatch!(block, list)

Pop the first [`nparameters`](@ref) parameters of list, then dispatch them to
the block tree `block`. See also [`dispatch!`](@ref).
"""
@interface popdispatch!(x::AbstractBlock, list::Vector) = popdispatch!(identity, x, list)

render_params(r::AbstractBlock, params) = params
render_params(r::AbstractBlock, params::Symbol) = render_params(r, Val(params))
render_params(r::AbstractBlock, ::Val{:random}) = (rand() for i=1:niparams(r))
render_params(r::AbstractBlock, ::Val{:zero}) = (zero(params_eltype(r)) for i in 1:niparams(r))

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
