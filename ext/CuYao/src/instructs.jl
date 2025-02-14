replace_first(x::NTuple{2}, v) = (v, x[2])
replace_first(x::NTuple{1}, v) = (v,)
prod2(x::NTuple{2}) = x[1] * x[2]
prod2(x::NTuple{1}) = x[1]

gpu_compatible(A::AbstractVecOrMat) = A |> staticize
gpu_compatible(A::StaticArray) = A

###################### unapply! ############################
function instruct!(::Val{2}, state::DenseCuVecOrMat, U0::AbstractMatrix, locs::NTuple{M, Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where {C, M}
    @debug "The generic U(N) matrix of size ($(size(U0))), on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
    nbit = log2dim1(state)
    # reorder a unirary matrix.
    U = gpu_compatible(all(TupleTools.diff(locs).>0) ? U0 : reorder(U0, collect(locs)|>sortperm))
    locked_bits = [clocs..., locs...]
    locked_vals = [cvals..., zeros(Int, M)...]
    locs_raw = gpu_compatible([i+1 for i in itercontrol(nbit, setdiff(1:nbit, locs), zeros(Int, nbit-M))])
    configs = itercontrol(nbit, locked_bits, locked_vals)

    len = length(configs)
    @kernel function kernel(state, locs_raw, U, configs, len)
        CUDA.assume(len > 0)
        sz = size(state)
        CUDA.assume(length(sz) == 1 || length(sz) == 2)
        i, j = @index(Global, NTuple)
        x = @inbounds configs[i]
        @inbounds unrows!(view(state, :, j), x .+ locs_raw, U)
    end

    @kernel function kernel_single_entry_diag(state, loc, val, configs, len)
        CUDA.assume(len > 0)
        sz = size(state)
        CUDA.assume(length(sz) == 1 || length(sz) == 2)
        i, j = @index(Global, NTuple)
        x = @inbounds configs[i]
        @inbounds state[x + loc, j] *= val
    end

    if U isa Diagonal && count(!isone, U.diag) == 1
        @debug "The single entry diagonal matrix, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
        k = findfirst(!isone, U.diag)
        loc = locs_raw[k]
        val = U.diag[k]
        kernel_single_entry_diag(get_backend(state))(state, loc, val, configs, len; ndrange=(len, size(state,2)))
    else
        kernel(get_backend(state))(state, locs_raw, U, configs, len; ndrange=(len, size(state,2)))
    end
    state
end
instruct!(::Val{2}, state::DenseCuVecOrMat, U0::IMatrix, locs::NTuple{M, Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where {C, M} = state
instruct!(::Val{2}, state::DenseCuVecOrMat, U0::SDSparseMatrixCSC, locs::NTuple{M, Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where {C, M} = instruct!(Val(2), state, U0 |> Matrix, locs, clocs, cvals)

################## General U1 apply! ###################
function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::SDSparseMatrixCSC, loc::Int)
    instruct!(Val(2), state, Matrix(U1), loc, clocs, cval)
end
function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::AbstractMatrix, loc::Int)
    @debug "The generic U(2) matrix of size ($(size(U1))), on: GPU, locations: $(loc)."
    a, c, b, d = U1
    nbit = log2dim1(state)
    step = 1<<(loc-1)
    configs = itercontrol(nbit, [loc], [0])

    len = length(configs)
    @kernel function kernel(state, a, b, c, d, len)
        i, j = @index(Global, NTuple)
        i = @inbounds configs[i]+1
        @inbounds u1rows!(view(state, :, j), i, i+step, a, b, c, d)
    end
    kernel(get_backend(state))(state, a, b, c, d, len; ndrange=(len, size(state,2)))
    return state
end

function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::SDPermMatrix, loc::Int)
    @debug "The single qubit permutation matrix of size ($(size(U1))), on: GPU, locations: $(loc)."
    nbit = log2dim1(state)
    b, c = U1.vals
    step = 1<<(loc-1)
    configs = itercontrol(nbit, [loc], [0])

    len = length(configs)
    @kernel function kernel(state, b, c, step, len, configs)
        i, j = @index(Global, NTuple)
        x = @inbounds configs[i] + 1
        @inbounds swaprows!(view(state, :, j), x, x+step, c, b)
    end
    kernel(get_backend(state))(state, b, c, step, len, configs; ndrange=(len, size(state,2)))
    return state
end

function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::SDDiagonal, loc::Int)
    @debug "The single qubit diagonal matrix of size ($(size(U1))), on: GPU, locations: $(loc)."
    a, d = U1.diag
    nbit = log2dim1(state)
    mask = bmask(loc)
    @kernel function kernel(state, a, d, mask)
        i, j = @index(Global, NTuple)
        state[i, j] *= anyone(i-1, mask) ? d : a
    end
    kernel(get_backend(state))(state, a, d, mask; ndrange=(size(state, 1), size(state, 2)))
    return state
end


YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U::IMatrix, loc::Int) = state

################## XYZ #############

_instruct!(state::DenseCuVecOrMat, ::Val{:X}, locs::NTuple{L,Int}) where {L} = _instruct!(state, Val(:X), locs, (), ())
function _instruct!(state::DenseCuVecOrMat, ::Val{:X}, locs::NTuple{L,Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where {L,C}
    @debug "The X gate, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    configs = itercontrol(nbit, [clocs..., locs[1]], [cvals..., 0])
    mask = bmask(locs...)
    len = length(configs)
    @kernel function kernel(state, mask, len, configs)
        i, j = @index(Global, NTuple)
        b = @inbounds configs[i]
        @inbounds swaprows!(view(state, :, j), b+1, flip(b, mask) + 1)
    end
    kernel(get_backend(state))(state, mask, len, configs; ndrange=(len, size(state,2)))
    return state
end

function _instruct!(state::DenseCuVecOrMat, ::Val{:Y}, locs::NTuple{C,Int}) where C
    @debug "The Y gate, on: GPU, locations: $(locs)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    mask = bmask(Int, locs...)
    configs = itercontrol(nbit, [locs[1]], [0])
    bit_parity = length(locs)%2 == 0 ? 1 : -1
    factor = (-im)^length(locs)
    len = length(configs)
    @kernel function kernel(state, mask, bit_parity, configs, len)
        i, j = @index(Global, NTuple)
        b = @inbounds configs[i]
        i_ = flip(b, mask) + 1
        factor1 = count_ones(b&mask)%2 == 1 ? -factor : factor
        factor2 = factor1*bit_parity
        @inbounds swaprows!(view(state, :, j), b+1, i_, factor2, factor1)
    end
    kernel(get_backend(state))(state, mask, bit_parity, configs, len; ndrange=(len, size(state,2)))
    return state
end

function _instruct!(state::DenseCuVecOrMat, ::Val{:Y}, locs::Tuple{Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where C
    @debug "The Y gate, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    configs = itercontrol(nbit, [clocs..., locs...], [cvals..., 0])
    mask = bmask(locs...)
    len = length(configs)
    @kernel function kernel(state, configs, mask, len)
        i, j = @index(Global, NTuple)
        b = @inbounds configs[i]
        @inbounds swaprows!(view(state, :, j), b+1, flip(b, mask) + 1, im, -im)
    end
    kernel(get_backend(state))(state, configs, mask, len; ndrange=(len, size(state,2)))
    return state
end

function _instruct!(state::DenseCuVecOrMat, ::Val{:Z}, locs::NTuple{C,Int}) where C
    @debug "The Z gate, on: GPU, locations: $(locs)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    mask = bmask(locs...)
    @kernel function kernel(state, mask)
        i, j = @index(Global, NTuple)
        state[i, j] *= count_ones((i-1)&mask)%2==1 ? -1 : 1
    end
    kernel(get_backend(state))(state, mask; ndrange=(size(state, 1), size(state, 2)))
    return state
end


for (G, FACTOR) in zip([:Z, :S, :T, :Sdag, :Tdag], [:(-one(Int32)), :(1f0im), :($(exp(im*π/4))), :(-1f0im), :($(exp(-im*π/4)))])
    if G !== :Z
        @eval function _instruct!(state::DenseCuVecOrMat, ::Val{$(QuoteNode(G))}, locs::NTuple{C,Int}) where C
            @debug "The $($(QuoteNode(G))) gate, on: GPU, locations: $(locs)."
            length(locs) == 0 && return state
            nbit = log2dim1(state)
            mask = bmask(Int32, locs...)
            @kernel function kernel(state, mask)
                i, j = @index(Global, NTuple)
                state[i, j] *= $FACTOR ^ count_ones(Int32(i-1)&mask)
            end
            kernel(get_backend(state))(state, mask; ndrange=(size(state, 1), size(state, 2)))
            return state
        end
    end
    @eval function _instruct!(state::DenseCuVecOrMat, ::Val{$(QuoteNode(G))}, locs::Tuple{Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where C
        @debug "The $($(QuoteNode(G))) gate, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
        ctrl = controller((clocs..., locs...), (cvals..., 1))
        @kernel function kernel(state, ctrl)
            i, j = @index(Global, NTuple)
            state[i, j] *= ctrl(i-1) ? $FACTOR : one($FACTOR)
        end
        kernel(get_backend(state))(state, ctrl; ndrange=(size(state, 1), size(state, 2)))
        return state
    end
end

for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    @eval begin
        function YaoArrayRegister.instruct!(::Val{2}, state::DenseCuVecOrMat, g::Val{$(QuoteNode(G))}, locs::NTuple{C,Int}) where C
            _instruct!(state, g, locs)
        end

        function YaoArrayRegister.instruct!(::Val{2}, state::DenseCuVecOrMat, g::Val{$(QuoteNode(G))}, locs::Tuple{Int})
            _instruct!(state, g, locs)
        end

        function YaoArrayRegister.instruct!(::Val{2}, state::DenseCuVecOrMat, g::Val{$(QuoteNode(G))}, locs::Tuple{Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where C
            _instruct!(state, g, locs, clocs, cvals)
        end

        function YaoArrayRegister.instruct!(::Val{2}, state::DenseCuVecOrMat, vg::Val{$(QuoteNode(G))}, locs::Tuple{Int}, cloc::Tuple{Int}, cval::Tuple{Int})
            _instruct!(state, vg, locs, cloc, cval)
        end
    end

end

function instruct!(::Val{2}, state::DenseCuVecOrMat, ::Val{:SWAP}, locs::Tuple{Int,Int})
    @debug "The SWAP gate, on: GPU, locations: $(locs)."
    b1, b2 = locs
    mask1 = bmask(b1)
    mask2 = bmask(b2)

    configs = itercontrol(log2dim1(state), [locs...], [1,0])
    @kernel function kernel(state, mask1, mask2)
        i, j = @index(Global, NTuple)
        b = configs[i]
        i = b+1
        i_ = b ⊻ (mask1|mask2) + 1
        swaprows!(view(state, :, j), i, i_)
    end
    kernel(get_backend(state))(state, mask1, mask2; ndrange=(length(configs), size(state,2)))
    state
end

############## other gates ################
# parametrized swap gate

function instruct!(::Val{2}, state::DenseCuVecOrMat, ::Val{:PSWAP}, locs::Tuple{Int, Int}, θ::Real)
    @debug "The PSWAP gate, on: GPU, locations: $(locs)."
    nbit = log2dim1(state)
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1 | mask2
    a, c, b_, d = mat(Rx(θ))
    e = exp(-im/2*θ)
    configs = itercontrol(nbit, [locs...], [0,0])
    len = length(configs)
    @kernel function kernel(state, mask2, mask12, configs, a, b_, c, d)
        i, j = @index(Global, NTuple)
        @inbounds x = configs[i]
        state[x+1, j] *= e
        state[x⊻mask12+1, j] *= e
        y = x ⊻ mask2
        @inbounds u1rows!(view(state, :, j), y+1, y⊻mask12+1, a, b_, c, d)
    end
    kernel(get_backend(state))(state, mask2, mask12, configs, a, b_, c, d; ndrange=(len, size(state,2)))
    state
end

function YaoBlocks._apply_fallback!(r::AbstractCuArrayReg{B,T}, b::AbstractBlock) where {B,T}
    YaoBlocks._check_size(r, b)
    r.state .= CUDA.adapt(CuArray{T}, mat(T, b)) * r.state
    return r
end

for RG in [:Rx, :Ry, :Rz]
    @eval function instruct!(
            ::Val{2}, 
            state::DenseCuVecOrMat{T},
            ::Val{$(QuoteNode(RG))},
            locs::Tuple{Int},
            theta::Number
        ) where {T}
        YaoArrayRegister.instruct!(Val(2), state, Val($(QuoteNode(RG))), locs, (), (), theta)
        return state
    end
end
