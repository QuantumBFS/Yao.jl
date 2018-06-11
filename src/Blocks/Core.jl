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

"""
    parameters(block) -> Vector

Returns a list of all parameters in block.
"""
function parameters end

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
function print_block(io::IO, block)

@static if VERSION < v"0.7-"
    print(io, summary(block))
else
    summary(io, block)
end

end
