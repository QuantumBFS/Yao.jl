export nqubits, address, state, focus!, isunitary, isreflexive, nparameters, datatype, mat, dispatch!, nbatch

# All exported methods and types docstring should be defined here.

function nqubits end
function address end
function state end
function focus! end

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
function datatype end

"""
    mat(block) -> Matrix
"""
function mat end
function dispatch! end
