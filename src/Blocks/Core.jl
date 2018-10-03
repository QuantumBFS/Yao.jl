export AbstractBlock

"""
    AbstractBlock

abstract type that all block will subtype from. `N` is the number of
qubits.
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
function npiarameters end
niparameters(::Type{X}) where {X <: AbstractBlock} = 0
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

"""
    parameter_type(block) -> Type

the type of iparameters.
"""
function parameter_type end
parameter_type(x::AbstractBlock) = Bool

"""
    mat(block) -> Matrix

Returns the matrix form of this block.
"""
function mat end

"""
    dispatch!(block, params)
    dispatch!(block, params...)

dispatch (using pop!) parameters to this block.
"""
function dispatch! end

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
    count = 0
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
    for blk in subblocks(c)
        append!(output, iparameters(blk))
    end
    output
end
