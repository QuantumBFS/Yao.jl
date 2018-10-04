export AbstractBlock

"""
    AbstractBlock

abstract type that all block will subtype from. `N` is the number of
qubits.
"""
abstract type AbstractBlock end

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
    nparameters(x) -> Integer

Returns the number of parameters of `x`.
"""
function nparameters end
nparameters(::Type{X}) where {X <: AbstractBlock} = 0
nparameters(x::AbstractBlock) = length(parameters(x))

"""
    parameters(block) -> Vector

Returns a list of all parameters in block.
"""
function parameters end
parameters(x::AbstractBlock) = ()

"""
    parameters(block) -> Type

the type of parameters.
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

dispatch parameters to this block.
"""
function dispatch! end

"""
    print_block(io, block)

define the style to print this block
"""
print_block(io::IO, block) = summary(io, block)

isprimitive(blk::AbstractBlock) = false
