export instruct!

"""
    instruct!(state, operator[, locs, control_locs, control_configs, theta])

instruction implementation for applying an operator to a quantum state.

This operator will be overloaded for different operator or state with
different types.
"""
function instruct! end

# empty gates
YaoBase.instruct!(
    state::AbstractVecOrMat,
    ::Any,
    locs::Tuple{},
    control_locs::NTuple{N1,Int} = (),
    control_configs::NTuple{N2,Int} = (),
) where {N1,N2} = state
