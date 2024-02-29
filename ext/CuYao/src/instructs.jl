# get index
macro idx(shape, grididx=1, ctxsym=:ctx)
    quote
        x = $(esc(shape))
        i = $linear_index($(esc(ctxsym)), $(esc(grididx)))
        i > $prod2(x) && return
        @inbounds Base.CartesianIndices(x)[i].I
    end
end
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
    @inline function kernel(ctx, state, locs_raw, U, configs, len)
        CUDA.assume(len > 0)
        sz = size(state)
        CUDA.assume(length(sz) == 1 || length(sz) == 2)
        inds = @idx replace_first(sz, len)
        x = @inbounds configs[inds[1]]
        @inbounds unrows!(piecewise(state, inds), x .+ locs_raw, U)
        return
    end

    @inline function kernel_single_entry_diag(ctx, state, loc, val, configs, len)
        CUDA.assume(len > 0)
        sz = size(state)
        CUDA.assume(length(sz) == 1 || length(sz) == 2)
        inds = @idx replace_first(sz, len)
        x = @inbounds configs[inds[1]]
        @inbounds piecewise(state, inds)[x + loc] *= val
        return
    end

    elements = len*size(state,2)
    if U isa Diagonal && count(!isone, U.diag) == 1
        @debug "The single entry diagonal matrix, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
        k = findfirst(!isone, U.diag)
        loc = locs_raw[k]
        val = U.diag[k]
        gpu_call(kernel_single_entry_diag, state, loc, val, configs, len; elements)
    else
        gpu_call(kernel, state, locs_raw, U, configs, len; elements)
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
    @inline function kernel(ctx, state, a, b, c, d, len)
        inds = @idx replace_first(size(state), len)
        i = @inbounds configs[inds[1]]+1
        @inbounds u1rows!(piecewise(state, inds), i, i+step, a, b, c, d)
        return
    end
    gpu_call(kernel, state, a, b, c, d, len; elements=len*size(state,2))
    return state
end

function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::SDPermMatrix, loc::Int)
    @debug "The single qubit permutation matrix of size ($(size(U1))), on: GPU, locations: $(loc)."
    nbit = log2dim1(state)
    b, c = U1.vals
    step = 1<<(loc-1)
    configs = itercontrol(nbit, [loc], [0])

    len = length(configs)
    function kernel(ctx, state, b, c, step, len, configs)
        inds = @idx replace_first(size(state), len)
        x = @inbounds configs[inds[1]] + 1
        @inbounds swaprows!(piecewise(state, inds), x, x+step, c, b)
        return
    end
    gpu_call(kernel, state, b, c, step, len, configs; elements=len*size(state,2))
    return state
end

function YaoArrayRegister.single_qubit_instruct!(state::DenseCuVecOrMat, U1::SDDiagonal, loc::Int)
    @debug "The single qubit diagonal matrix of size ($(size(U1))), on: GPU, locations: $(loc)."
    a, d = U1.diag
    nbit = log2dim1(state)
    mask = bmask(loc)
    @inline function kernel(ctx, state, a, d, mask)
        inds = @cartesianidx state
        i = inds[1]
        piecewise(state, inds)[i] *= anyone(i-1, mask) ? d : a
        return
    end
    gpu_call(kernel, state, a, d, mask; elements=length(state))
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
    @inline function kernel(ctx, state, mask, len, configs)
        inds = @idx replace_first(size(state), len)
        b = @inbounds configs[inds[1]]
        @inbounds swaprows!(piecewise(state, inds), b+1, flip(b, mask) + 1)
        return
    end
    gpu_call(kernel, state, mask, len, configs; elements=len*size(state,2))
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
    @inline function kernel(ctx, state, mask, bit_parity, configs, len)
        inds = @idx replace_first(size(state), len)
        b = @inbounds configs[inds[1]]
        i_ = flip(b, mask) + 1
        factor1 = count_ones(b&mask)%2 == 1 ? -factor : factor
        factor2 = factor1*bit_parity
        @inbounds swaprows!(piecewise(state, inds), b+1, i_, factor2, factor1)
        return
    end
    gpu_call(kernel, state, mask, bit_parity, configs, len; elements=len*size(state,2))
    return state
end

function _instruct!(state::DenseCuVecOrMat, ::Val{:Y}, locs::Tuple{Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where C
    @debug "The Y gate, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    configs = itercontrol(nbit, [clocs..., locs...], [cvals..., 0])
    mask = bmask(locs...)
    len = length(configs)
    @inline function kernel(ctx, state, configs, mask, len)
        inds = @idx replace_first(size(state), len)
        b = @inbounds configs[inds[1]]
        @inbounds swaprows!(piecewise(state, inds), b+1, flip(b, mask) + 1, im, -im)
        return
    end
    gpu_call(kernel, state, configs, mask, len; elements=len*size(state,2))
    return state
end

function _instruct!(state::DenseCuVecOrMat, ::Val{:Z}, locs::NTuple{C,Int}) where C
    @debug "The Z gate, on: GPU, locations: $(locs)."
    length(locs) == 0 && return state
    nbit = log2dim1(state)
    mask = bmask(locs...)
    @inline function kernel(ctx, state, mask)
        inds = @cartesianidx state
        i = inds[1]
        piecewise(state, inds)[i] *= count_ones((i-1)&mask)%2==1 ? -1 : 1
        return
    end
    gpu_call(kernel, state, mask; elements=length(state))
    return state
end


for (G, FACTOR) in zip([:Z, :S, :T, :Sdag, :Tdag], [:(-one(Int32)), :(1f0im), :($(exp(im*π/4))), :(-1f0im), :($(exp(-im*π/4)))])
    if G !== :Z
        @eval function _instruct!(state::DenseCuVecOrMat, ::Val{$(QuoteNode(G))}, locs::NTuple{C,Int}) where C
            @debug "The $($(QuoteNode(G))) gate, on: GPU, locations: $(locs)."
            length(locs) == 0 && return state
            nbit = log2dim1(state)
            mask = bmask(Int32, locs...)
            @inline function kernel(ctx, state, mask)
                inds = @cartesianidx state
                i = inds[1]
                piecewise(state, inds)[i] *= $FACTOR ^ count_ones(Int32(i-1)&mask)
                return
            end
            gpu_call(kernel, state, mask; elements=length(state))
            return state
        end
    end
    @eval function _instruct!(state::DenseCuVecOrMat, ::Val{$(QuoteNode(G))}, locs::Tuple{Int}, clocs::NTuple{C, Int}, cvals::NTuple{C, Int}) where C
        @debug "The $($(QuoteNode(G))) gate, on: GPU, locations: $(locs), controlled by: $(clocs) = $(cvals)."
        ctrl = controller((clocs..., locs...), (cvals..., 1))
        @inline function kernel(ctx, state, ctrl)
            inds = @cartesianidx state
            i = inds[1]
            piecewise(state, inds)[i] *= ctrl(i-1) ? $FACTOR : one($FACTOR)
            return
        end
        gpu_call(kernel, state, ctrl; elements=length(state))
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
    function kf(ctx, state, mask1, mask2)
        inds = @idx replace_first(size(state), length(configs))

        b = configs[inds[1]]
        i = b+1
        i_ = b ⊻ (mask1|mask2) + 1
        swaprows!(piecewise(state, inds), i, i_)
        nothing
    end
    gpu_call(kf, state, mask1, mask2; elements=length(configs)*size(state,2))
    state
end

############## other gates ################
# parametrized swap gate

function instruct!(::Val{2}, state::DenseCuVecOrMat, ::Val{:PSWAP}, locs::Tuple{Int, Int}, θ::Real)
    @debug "The PSWAP gate, on: GPU, locations: $(locs)."
    nbit = log2dim1(state)
    mask1 = bmask(locs[1])
    mask2 = bmask(locs[2])
    mask12 = mask1|mask2
    a, c, b_, d = mat(Rx(θ))
    e = exp(-im/2*θ)
    configs = itercontrol(nbit, [locs...], [0,0])
    len = length(configs)
    @inline function kernel(ctx, state, mask2, mask12, configs, a, b_, c, d)
        inds = @idx replace_first(size(state), len)
        @inbounds x = configs[inds[1]]
        piecewise(state, inds)[x+1] *= e
        piecewise(state, inds)[x⊻mask12+1] *= e
        y = x ⊻ mask2
        @inbounds u1rows!(piecewise(state, inds), y+1, y⊻mask12+1, a, b_, c, d)
        return
    end
    gpu_call(kernel, state, mask2, mask12, configs, a, b_, c, d; elements=len*size(state,2))
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
