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
    setparameters!([elementwisefunction], r::AbstractBlock, params) -> AbstractBlock

set intrinsics parameter for block.
"""
function setiparameters end
setiparameters!(r::AbstractBlock, params) = r
setiparameters!(func::Function, r::AbstractBlock, params) = setiparameters!(r, func.(r |> iparameters, params))

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
    dispatch!([func::Function], block::AbstractBlock, params)
    dispatch!!([func::Function], block::AbstractBlock, params)

dispatch parameters to this block, `dispatch!!` will pop! out all params.
"""
dispatch!(block::AbstractBlock, params) = dispatch!!(block, params |> collect)
dispatch!(func::Function, block::AbstractBlock, params) = dispatch!!(func, block, params |> collect)
function dispatch!!(r::AbstractBlock, params)
    setiparameters!(r, (popfirst!(params) for i=1:niparameters(r)))
    for blk in subblocks(r)
        dispatch!!(blk, params)
    end
    r
end
function dispatch!!(func::Function, r::AbstractBlock, params)
    setiparameters!(func, r, (popfirst!(params) for i=1:niparameters(r)))
    for blk in subblocks(r)
        dispatch!!(func, blk, params)
    end
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
