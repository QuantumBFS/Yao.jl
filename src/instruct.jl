export instruct!

"""
    instruct(state, operator[, locs, control_locs, control_configs])

instruction implementation for applying an operator to a quantum state.

This operator will be overloaded for different operator or state with
different types.
"""
function instruct! end

# empty gates
YaoBase.instruct!(state::AbstractVecOrMat, ::Any,
    locs::Tuple{}, control_bits::NTuple{N1, Int}=(),
    control_vals::NTuple{N2, Int}=()) where {N1, N2} = state
