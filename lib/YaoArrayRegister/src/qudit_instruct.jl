using SparseArrays
function YaoAPI.instruct!(::Val{D},
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M,Int},
    control_locs::NTuple{C,Int},
    control_bits::NTuple{C,Int}
) where {T,M,C,D}
    if length(control_locs) !== 0 || length(control_bits) !== 0
        error("controlled qudit gates are not supported!")
    end
    if M == 1
        return single_qubit_instruct!(state, operator, locs, control_locs, control_bits)
    end
    return instruct!(Val(D), state, operator, locs)
end

function YaoAPI.instruct!(::Val{D},
    state::AbstractVecOrMat{T},
    operator::AbstractMatrix{T},
    locs::NTuple{M,Int},
) where {T,M,D}
    # prepare instruct
    operator = sort_unitary(Val{D}(), operator, locs)
    ndits = logdi(size(state, 1), D)
    qudit_instruct!(Val{D}(), ndits, state, autostatic(operator), TupleTools.sort(locs))
end

function qudit_instruct!(::Val{D}, nbits::Int, state::AbstractVecOrMat{T}, operator::AbstractMatrix{T}, locs::NTuple{M,Int}) where {T,M,D}
    strides = ntuple(i->D^(i-1), nbits)
    baselocs = (setdiff(1:nbits, locs)...,)
    basestrides = map(i->strides[i], baselocs)
    substrides = map(i->strides[i], locs)

    subindices = SVector(ntuple(i->map_index(Val(D), i-1, substrides), D^M))
    #baseindices = [map_index(Val(D), i, basestrides) for i=0:D^(nbits-M)-1]

    _instruct!(Val(D), state, autostatic(operator), subindices, basestrides)
    return state
end

# specialize: IMatrix
function qudit_instruct!(::Val{D}, nbits::Int, state::AbstractVecOrMat{T}, operator::IMatrix, locs::NTuple{M,Int}) where {T,M,D}
    return state
end

@generated function _instruct!(::Val{D}, state::AbstractVecOrMat, U::AbstractMatrix, subindices::SVector, basestrides::NTuple{BN}) where {D,BN}
    quote
        sumc = length(basestrides) == 0 ? 1 : 1 - sum(basestrides)
        Base.Cartesian.@nloops($BN, i, d->1:$D,
                d->(@inbounds sumc += i_d*basestrides[d]), # PRE
                d->(@inbounds sumc -= i_d*basestrides[d]), # POST
                begin # BODY
                    @inbounds unrows!(state, subindices .+ sumc, U)
                end)

    end
end
@inline function map_index(::Val{D}, x, strides::NTuple{M,Int}) where {D,M}
    res = zero(x)
    for i=1:M
        x, rem = divrem(x, D)
        res += rem * strides[i]
    end
    return res
end

# specialize: Diagonal
function qudit_instruct!(::Val{D},
    nbits::Int,
    state::AbstractVecOrMat{T},
    operator::SDDiagonal{T},
    locs::NTuple{M,Int},
) where {T,M,D}
    # create stride for indexing
    strides = ntuple(i->D^(i-1), nbits)
    baselocs = (setdiff(1:nbits, locs)...,)
    basestrides = map(i->strides[i], baselocs)
    substrides = map(i->strides[i], locs)

    # allocate storage
    CI = CartesianIndices(ntuple(i->D, M))
    @threads for i=1:size(operator, 1)  # very limited multi-threading power
        # set indices
        @inbounds I = CI[i].I
        @inbounds ioffset = sum(i->(I[i]-1) * substrides[i], 1:M)
        instrloop_diag!(Val(D), state, operator.diag[i], ioffset, basestrides)
    end
    return state
end

@generated function instrloop_diag!(::Val{D}, state::AbstractVecOrMat, v, ioffset::Int, basestrides::NTuple{BN}) where {D,BN}
    quote
        sumc = 1 - sum(basestrides)
        Base.Cartesian.@nloops($BN, i, d->1:$D,
                d->(@inbounds sumc += i_d*basestrides[d]), # PRE
                d->(@inbounds sumc -= i_d*basestrides[d]), # POST
                begin # BODY
                    @inbounds mulrow!(state, ioffset + sumc, v)
                end)

    end
end

# function qudit_instruct!(::Val{D}, nbits::Int, state::AbstractVecOrMat{T}, operator::SDSparseMatrixCSC{T}, locs::NTuple{M,Int}) where {T,M,D}
#     stateout = zero(state)
#     accum_instruct!(Val(D), nbits, stateout, state, TupleTools.sort(locs), autostatic(operator))
#     return copyto!(state, stateout)
# end

# function accum_instruct!(::Val{D}, nbits::Int, stateout::AbstractVecOrMat{T}, statein::AbstractVecOrMat{T}, locs::NTuple{C}, mat::IMatrix) where {D,C,T}
#     return stateout .+= statein
# end

# function accum_instruct!(::Val{D}, nbits::Int, stateout::AbstractVecOrMat{T}, statein::AbstractVecOrMat{T}, locs::NTuple{C}, mat::SDSparseMatrixCSC) where {D,C,T}
#     @assert size(stateout) == size(statein)
#     # create stride for indexing
#     strides = ntuple(i->D^(i-1), nbits)
#     baselocs = (setdiff(1:nbits, locs)...,)
#     basestrides = map(i->strides[i], baselocs)
#     substrides = map(i->strides[i], locs)

#     # allocate storage
#     CI = CartesianIndices(ntuple(i->D, C))
#     @inbounds for (i, j, v) in zip(findnz(mat)...)
#         # set indices
#         I, J = CI[i].I, CI[j].I
#         ioffset = sum(i->(I[i]-1) * substrides[i], 1:C)
#         joffset = sum(i->(J[i]-1) * substrides[i], 1:C)
#         instrloop!(Val(D), stateout, statein, v, ioffset, joffset, basestrides)
#     end
#     return stateout
# end

# @generated function instrloop!(::Val{D}, stateout::AbstractVecOrMat, statein::AbstractVecOrMat, v, ioffset::Int, joffset::Int, basestrides::NTuple{BN}) where {D,BN}
#     quote
#         sumc = 1 - sum(basestrides)
#         Base.Cartesian.@nloops($BN, i, d->1:$D,
#                 d->(@inbounds sumc += i_d*basestrides[d]), # PRE
#                 d->(@inbounds sumc -= i_d*basestrides[d]), # POST
#                 begin # BODY
#                     @inbounds accrow!(stateout, ioffset + sumc, statein, joffset + sumc, v)
#                 end)

#     end
# end

# @inline function accrow!(stateout::AbstractVector, iout, statein::AbstractVector, iin, v)
#     @inbounds stateout[iout] += v * statein[iin]
# end

# @inline function accrow!(stateout::AbstractMatrix, iout, statein::AbstractMatrix, iin, v)
#     for j=size(stateout, 2)
#         @inbounds stateout[iout, j] += v * statein[iin, j]
#     end
# end

# TODO: add single qudit gate instruction.
# TODO: add diagonal qudit gate instruction.
# TODO: speed up sparse matrix and pm matrix gate.
