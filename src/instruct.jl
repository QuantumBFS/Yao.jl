"""
    instruct(state, operator[, locs, control_bits, control_vals])

instruction implementation for applying an operator to a quantum state.

This operator will be overloaded for different operator or state with
different types.
"""
function instruct end

# Move this to DenseRegister
# general instruction
function instruct(
        state::AbstractVecOrMat{T},
        operator::AbstractMatrix{T},
        locs::NTuple{M, Int},
        control_bits::NTuple{C, Int} = (),
        control_vals::NTuple{C, Int} = ()) where {T, M, C}
###########################################

end

# one-qubit instruction
function instruct(
        state::AbstractVecOrMat{T},
        operator::AbstractMatrix{T},
        locs::Tuple{Int})
###########################################
    a, c, b, d = U1
    step = 1<<(ibit-1)
    step_2 = 1<<ibit
    for j = 0:step_2:size(state, 1)-step
        @inbounds @simd for i = j+1:j+step
            u1rows!(state, i, i+step, a, b, c, d)
        end
    end
    state
end
