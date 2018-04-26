"""
    AbstractRegister{M, B, T, N} <: AbstractArray{T, N}

Abstract type for quantum registers, all quantum registers supports
the interface of julia arrays.

## Parameters
- `M` is the number of qubits
- `B` is the batch size
- `N` is the actual dimension (number of packed legs, batch dimension is the last dimension if batch size is not 0).
"""
abstract type AbstractRegister{M, B, T, N} <: AbstractArray{T, N} end

# register properties
nqubit(reg::AbstractRegister{M}) where M = M
nbatch(reg::AbstractRegister{M, B}) where {M, B} = B
data(reg::AbstractRegister) = reg.data

struct Register{M, B, T, N} <: AbstractRegister{M, B, T, N}
    data::Array{T, N}
    ids::Vector{Int}
end

# We store the state with a M-dimentional tensor by default
# This will reduce memory allocation by allowing us use
# permutedims! rather than permutedims.

# Type Inference
Register(nqubit::Int, nbatch::Int, data::Array{T, N}, ids::Vector{Int}) where {M, T, N} =
    Register{nqubit, nbatch, T, N}(data, ids)

Register(nqubit::Int, nbatch::Int, data::Array) =
    Register(nqubit, nbatch, data, Vector(1:nqubit))

# calculate number of qubits from data array
function Register(nbatch::Int, data::Array)
    len = length(data)
    ispow2(len) || throw(Compat.InexactError(:Register, Register, data))
    Register(log2i(len), nbatch, data)
end

# no batch
Register(data::Array) = Register(1, data)

#########################
# Default Initialization
#########################

# NOTE: we store a rank-n tensor for n qubits by default,
# we can always optimize this by add other kind of
# register for specific tasks
Register(::Type{T}, nqubit::Integer, nbatch::Integer, ids::Vector) where T =
    Register(nqubit, nbatch, zeros(T, ntuple(x->2, Val{nqubit})..., nbatch), ids)
Register(::Type{T}, nqubit::Integer, ids::Vector) where T =
    Register(nqubit, nbatch, zeros(T, ntuple(x->2, Val{nqubit})...), ids)
Register(::Type{T}, nqubit::Integer, nbatch::Integer) where T =
    Register(T, nqubit, nbatch, Tuple(1:nqubit))
Register(::Type{T}, nqubit::Integer) where T =
    Register(T, nqubit, Tuple(1:nqubit))

# We use Compelx128 by default
Register(nqubit::Integer, nbatch::Integer, ids::Vector) =
    Register(Complex128, nqubit, nbatch, ids)
Register(nqubit::Integer, ids::Vector) =
    Register(Complex128, nqubit, ids)
Register(nqubit::Integer, nbatch::Integer) =
    Register(Complex128, nqubit, nbatch)
Register(nqubit::Integer) =
    Register(Complex128, nqubit)


# use array interface
# TODO: use @forward instead
import Base: eltype, length, ndims, size, eachindex, 
    getindex, setindex!, stride, strides, copy
import Compat: axes

eltype(x::Register{M, B, T, N}) where {M, B, T, N} = T
length(x::Register) = length(x.data)
ndims(x::Register) = ndims(x.data)
size(x::Register) = size(x.data)
size(x::Register, n::Integer) = size(x.data, n)
axes(x::Register) = axes(x.data)
axes(x::Register, d::Integer) = axes(x.data, d)
eachindex(x::Register) = eachindex(x.data)
stride(x::Register, k::Integer) = stride(x.data, k)
strides(x::Register) = strides(x.data)
getindex(x::Register, index::Integer...) = getindex(x.data, index...)
getindex(x::Register, index::NTuple{N, T}) where {N, T <: Integer} = getindex(x.data, index...)
setindex!(x::Register, val, index::Integer...) = setindex!(x.data, val, index...)
setindex!(x::Register, val, index::NTuple{N, T}) where {N, T <: Integer} = setindex!(x.data, val, index...)
copy(x::Register{M, T, N}) where {M, T, N} = Register{M, T, N}(copy(x.data))


#################
# Batch Iterator
#################

export batch

# batch iterator
struct BatchIter{M, B, T, N}
    reg::Register{M, B, T, N}
end

batch(x::Register) = BatchIter(x)

import Base: start, next, done, length, eltype

start(x::BatchIter) = 1
next(x::BatchIter{M, B, T, N}, state) where {M, B, T, N} =
    view(x.reg.data, ntuple(x->:, Val{N-1})..., state), state+1
next(x::BatchIter{M, 1, T, N}, state) where {M, T, N} =
    view(x.reg.data, ntuple(x->:, Val{N})...), state+1
done(x::BatchIter{M, B, T, N}, state) where {M, B, T, N} = state > B
length(x::BatchIter{M, B, T, N}) where {M, B, T, N} = B


## Dimension Permutation & Reshape
import Base: reshape, permutedims, permutedims!

reshape(reg::Register{M, B, T, N}, dims::Dims) where {M, B, T, N} =
    Register(M, B, reshape(reg.data, dims), reg.ids)
reshape(reg::Register, dims...) = reshape(reg, dims)

"""
    pack!(dst, src, ids)

pack `ids` together to the first k-dimensions.
"""
function pack!(dst::Register{M, B, T, M}, src::Register{M, B, T, M}, ids::NTuple{K, Int}) where {M, B, T, K}
    ids = sort!(Vector(ids))
    inds = findin(src.ids, ids)
    perm = copy(src.ids)
    deleteat!(perm, inds)
    prepend!(perm, ids)
    dst.ids .= perm
    B == 1 || append!(perm, M+1)
    permutedims!(dst.data, src.data, perm)
    dst
end

pack!(reg::Register, ids) = pack!(reg, reg, ids)
pack!(reg::Register, ids...) = pack!(reg, ids)

export focus

"""
    focus(register, ids...)

pack tensor legs with ids together and reshape the register to
(exposed, remain, batch) or (exposed, remain) depending on register
type (with or without batch).
"""
focus(reg::Register, ids...) = focus(reg, ids)

function focus(src::Register{M, B, T, M}, ids::NTuple{K, Int}) where {M, B, T, K}
    pack!(src, ids)
    exposed_size = 2^K
    remained_size = 2^(M-K)
    data = reshape(src.data, exposed_size, remained_size, B)
    Register(M, B, data, src.ids)
end

function focus(src::Register{M, 1, T, M}, ids::NTuple{K, Int}) where {M, T, K}
    pack!(src, ids)
    exposed_size = 2^K
    remained_size = 2^(M-K)
    data = reshape(src.data, exposed_size, remained_size)
    Register(M, 1, data, src.ids)
end

focus(src::Register{M, B}, ids::NTuple) where {M, B} =
    focus(reshape(src, ntuple(x->2, Val{M})..., B), ids)
focus(src::Register{M, 1}, ids::NTuple) where M =
    focus(reshape(src, ntuple(x->2, Val{M})), ids)
