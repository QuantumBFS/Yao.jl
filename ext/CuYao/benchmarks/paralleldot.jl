function paralleldot(matrices::CuVector, ptrA, ptrB)
    @inline function kernel(ctx, matrices)
        inds = @cartesianidx state
        i = inds[1]
        piecewise(state, inds)[i] *= anyone(i-1, mask) ? d : a
        return
    end
    gpu_call(kernel, state, a, d, mask; elements=length(state))
    return state
end

