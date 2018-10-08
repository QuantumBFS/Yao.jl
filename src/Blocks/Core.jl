export AbstractBlock

"""
    AbstractBlock

abstract type that all block will subtype from. `N` is the number of qubits.

Required interfaces
    * `apply!` or (and) `mat`

Interfaces for parametric blocks.

    * iparameters
    * setiparameters
"""
abstract type AbstractBlock end

"""
    subblocks(blk::AbstractBlock) -> Tuple

return a tuple of all sub-blocks in this block.
"""
function subblocks end
subblocks(blk::AbstractBlock) = ()

"""
    chsubblocks(pb::AbstractBlock, blks) -> AbstractBlock

Change `subblocks` of target block.
"""
chsubblocks(pb::AbstractBlock, blks) = length(blks)==0 ? pb : throws(ArgumentError("size of blocks not match!"))

"""
    apply!(reg, block, [signal])

apply a `block` to a register `reg` with or without a cache signal.
"""
function apply! end

"""
    applymatrix(g::AbstractBlock) -> Matrix

Transform the apply! function of specific block to dense matrix.
"""
applymatrix(g::AbstractBlock) = linop2dense(r->statevec(apply!(register(r), g)), nqubits(g))

"""
    isunitary(x) -> Bool

Test whether this operator is unitary.
"""
function isunitary end

"""
    isreflexive(x) -> Bool

Test whether this operator is reflexive.
"""
function isreflexive end

"""
    niparameters(x) -> Integer

Returns the number of parameters of `x`.
"""
function niparameters end
niparameters(x::AbstractBlock) = length(iparameters(x))

"""
    iparameters(block) -> Vector

Returns a list of all intrinsic (not from sublocks) parameters in block.
"""
function iparameters end
iparameters(x::AbstractBlock) = ()

"""
    setparameters!([elementwisefunction], r::AbstractBlock, params::Number...) -> AbstractBlock
    setparameters!([elementwisefunction], r::AbstractBlock, :random) -> AbstractBlock
    setparameters!([elementwisefunction], r::AbstractBlock, :zero) -> AbstractBlock

set intrinsics parameter for block, input `params` can be numbers or :random or :zero.
"""
function setiparameters end
setiparameters!(r::AbstractBlock, params::Number...) = r
setiparameters!(func::Function, r::AbstractBlock, params::Number...) = setiparameters!(r, func.(r |> iparameters, params)...)
setiparameters!(r::AbstractBlock, params::Symbol) = setiparameters!(r, Val(params))
setiparameters!(r::AbstractBlock, ::Val{:random}) = niparameters(r) == 0 ? r : setiparameters!(r, rand(niparameters(r))...)
setiparameters!(r::AbstractBlock, ::Val{:zero}) = niparameters(r) == 0 ? r : setiparameters!(r, zeros(niparameters(r))...)

"""
    parameter_type(block) -> Type

the type of iparameters.
"""
function parameter_type end
function parameter_type(c::AbstractBlock)
    promote_type(eltype(c |> iparameters), [parameter_type(each) for each in subblocks(c)]...)
end


"""
    mat(block) -> Matrix

Returns the matrix form of this block.
"""
function mat end

"""
    dispatch!([func::Function], block::AbstractBlock, params) -> AbstractBlock
    dispatch!([func::Function], block::AbstractBlock, :random) -> AbstractBlock
    dispatch!([func::Function], block::AbstractBlock, :zero) -> AbstractBlock

dispatch! parameters into this circuit, here `params` is an iterable.

If instead of iterable, a symbol `:random` or `:zero` is provided,
random numbers (its behavior is specified by `setiparameters!`) or 0s will be broadcasted into circuits.

using `dispatch!!` is more efficient, but will pop! out all params inplace.
"""
dispatch!(block::AbstractBlock, params) = dispatch!!(block, params |> collect)
dispatch!(func::Function, block::AbstractBlock, params) = dispatch!!(func, block, params |> collect)
"""
    dispatch!!([func::Function], block::AbstractBlock, params) -> AbstractBlock

Similar to `dispatch!`, but will pop! out params inplace, it can not more efficient.
"""
function dispatch!!(r::AbstractBlock, params)
    setiparameters!(r, (popfirst!(params) for i=1:niparameters(r))...)
    for blk in subblocks(r)
        dispatch!!(blk, params)
    end
    r
end
function dispatch!!(func::Function, r::AbstractBlock, params)
    setiparameters!(func, r, (popfirst!(params) for i=1:niparameters(r))...)
    for blk in subblocks(r)
        dispatch!!(func, blk, params)
    end
    r
end

function dispatch!(func::Function, r::AbstractBlock, params::Symbol)
    setiparameters!(func, r, params)
    dispatch!.(func, r |> subblocks, params)
    r
end

function dispatch!(r::AbstractBlock, params::Symbol)
    setiparameters!(r, params)
    dispatch!.(r |> subblocks, params)
    r
end

"""
    print_block(io, block)

define the style to print this block
"""
function print_block(io::IO, block)
    summary(io, block)
end

"""
    nparameters(c::AbstractBlock) -> Int

number of parameters, including parameters in sublocks.
"""
function nparameters(c::AbstractBlock)
    count = niparameters(c)
    for each in subblocks(c)
        count += nparameters(each)
    end
    count
end

"""
    parameters(c::AbstractBlock, output=Float64[]) -> Vector

get all parameters including sublocks.
"""
function parameters(c::AbstractBlock, output=Float64[])
    append!(output, iparameters(c))
    for blk in subblocks(c)
        append!(output, parameters(blk))
    end
    output
end
