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
@interface function apply!(r::AbstractRegister, b::AbstractBlock)
    r.state .= mat(b) * r
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
    parameters(block)

Returns the parameters of node `block`, default is an empty tuple.
"""
@interface parameters(x::AbstractBlock) = ()

"""
    setparameters!(block, itr)
    setparameters!(block, params...)

Set the parameters of `block`.
"""
@interface setparameters!(x::AbstractBlock, it) = setparameters!(x, it...)

"""
    setparameters(f, block, collection)

Set parameters of `block` to the value in `collection` mapped by `f`.
"""
@interface setparameters!(f::Function, x::AbstractBlock, it) = setparameters!(x, map(f, it))

"""
    setparameters(f, block, symbol)

Set the parameters to a given symbol, which can be :zero, :random.
"""
@interface setparameters!(f::Function, x::AbstractBlock, it::Symbol) = setparameters(f, x, render_params(x, it))

"""
    allparameters(block)

Returns all the parameters contained in block tree with given root `block`.
"""
@interface allparameters(x::AbstractBlock) = allparameters!(allparam_eltype(x)[], x)

"""
    allparameters!(out, block)

Append all the parameters contained in block tree with given root `block` to
`out`.
"""
@interface allparameters!(out, x::AbstractBlock) = prewalk(blk->append!(out, parameters(blk)), x)

"""
    nparameters(block) -> Int

Return number of parameters in `block`. See also [`nallparameters`](@ref).
"""
@interface nparameters(x::AbstractBlock) = length(parameters(x))

@interface function nallparameters(x::AbstractBlock)
    count = nparameters(x)
    for each in subblocks(x)
        count += nallparameters(each)
    end
    return count
end

"""
    param_eltype(block)

Return the element type of [`parameters`](@ref).
"""
@interface param_eltype(x::AbstractBlock) = eltype(parameters(x))

"""
    allparam_eltype(x)

Return the element type of [`allparameters`](@ref).
"""
@interface function allparam_eltype(x::AbstractBlock)
    T = param_eltype(x)
    for each in subblocks(x)
        T = promote_type(T, param_eltype(each))
    end
    return T
end

"""
    dispatch!(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`.
"""
@interface function dispatch!(f::Function, x::AbstractBlock, it)
    @assert length(it) == nallparameters(x) "expect $(nallparameters(x)) parameters, got $(length(it))"
    setparameters!(f, x, Iterators.take(it, nparameters(x)))
    it = Iterators.drop(it, nparameters(x))
    for each in subblocks(x)
        dispatch!(f, each, it)
    end
    return x
end

function dispatch!(f::Function, x::AbstractBlock, it::Symbol)
    @assert length(it) == nallparameters(x) "expect $(nallparameters(x)) parameters, got $(length(it))"
    setparameters!(f, x, it)
    for each in subblocks(x)
        dispatch!(f, each, it)
    end
    return x
end

"""
    popdispatch!(f, block, list)

Pop the first [`nallparameters`](@ref) parameters of list, map them with a function
`f`, then dispatch them to the block tree `block`. See also [`dispatch!`](@ref).
"""
@interface function popdispatch!(f::Function, x::AbstractBlock, list::Vector)
    setparameters!(x, ntuple(()->f(popfirst!(list)), nparameters(x)))
    for each in subblocks(x)
        popdispatch!(x, list)
    end
    return x
end

"""
    popdispatch!(block, list)

Pop the first [`nallparameters`](@ref) parameters of list, then dispatch them to
the block tree `block`. See also [`dispatch!`](@ref).
"""
@interface popdispatch!(x::AbstractBlock, list::Vector) = popdispatch!(identity, x, list)

"""
    HasParameters{X} <: SimpleTraits.Trait

Block `X` has parameters.
"""
@traitdef HasParameters{X <: AbstractBlock}

@generated function SimpleTraits.trait(::Type{HasParameters{X}}) where X
    hasmethod(parameters, Tuple{X}) ? :(HasParameters{X}) : :(Not{HasParameters{X}})
end

render_params(r::AbstractBlock, params) = params
render_params(r::AbstractBlock, params::Symbol) = render_params(r, Val(params))
render_params(r::AbstractBlock, ::Val{:random}) = (rand() for i=1:nparameters(r))
render_params(r::AbstractBlock, ::Val{:zero}) = (zero(param_eltype(r)) for i in 1:nparameters(r))
