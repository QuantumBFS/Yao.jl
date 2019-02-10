export instruct!

"""
    instruct(state, operator[, locs, control_bits, control_vals])

instruction implementation for applying an operator to a quantum state.

This operator will be overloaded for different operator or state with
different types.
"""
function instruct! end
