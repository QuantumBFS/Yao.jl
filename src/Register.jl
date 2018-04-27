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

export nqubit, nbatch, qubits, state, statevec
# register properties
nqubit(reg::AbstractRegister{M}) where M = M
nbatch(reg::AbstractRegister{M, B}) where {M, B} = B
# We assume each register has a member named data and ids
# overload this if there is not
qubits(reg::AbstractRegister{M}) where M = reg.ids
state(reg::AbstractRegister) = reg.state
statevec(reg::AbstractRegister{M, B, T, N}) where {M, B, T, N} = reshape(reg.state, 2^M, B)
statevec(reg::AbstractRegister{M, B, T, 2}) where {M, B, T} = reg.state
statevec(reg::AbstractRegister{M, 1, T, N}) where {M, T, N} = reshape(reg.state, 2^M)
statevec(reg::AbstractRegister{M, 1, T, 1}) where {M, T} = reg.state


# provide view method if data type supports
export view_batch
import Base: view
# TODO: add SubRegister as return type of view_batch
view_batch(reg::AbstractRegister{M, B, T, N}, ibatch::Int) where {M, B, T, N} =
    view(state(reg), ntuple(x->:, Val{N-1})..., ibatch)
view_batch(reg::AbstractRegister{M, 1, T, N}, ibatch::Int) where {M, T, N} =
    view(state(reg), ntuple(x->:, Val{N})...)
view(reg::AbstractRegister, dims...) = view(state(reg), dims...)


# use array interface
# TODO: use @forward instead
import Base: eltype, length, ndims, size, eachindex, 
    getindex, setindex!, stride, strides, copy
import Compat: axes

eltype(x::AbstractRegister{M, B, T, N}) where {M, B, T, N} = T
length(x::AbstractRegister) = length(state(x))
ndims(x::AbstractRegister) = ndims(state(x))
size(x::AbstractRegister) = size(state(x))
size(x::AbstractRegister, n::Integer) = size(state(x), n)
axes(x::AbstractRegister) = axes(state(x))
axes(x::AbstractRegister, d::Integer) = axes(state(x), d)
eachindex(x::AbstractRegister) = eachindex(state(x))
stride(x::AbstractRegister, k::Integer) = stride(state(x), k)
strides(x::AbstractRegister) = strides(state(x))
getindex(x::AbstractRegister, index::Integer...) = getindex(state(x), index...)
getindex(x::AbstractRegister, index::NTuple{N, T}) where {N, T <: Integer} = getindex(state(x), index...)
setindex!(x::AbstractRegister, val, index::Integer...) = (setindex!(state(x), val, index...); x)
setindex!(x::AbstractRegister, val, index::NTuple{N, T}) where {N, T <: Integer} = (setindex!(state(x), val, index...); x)
copy(x::AbstractRegister{M, B, T, N}) where {M, B, T, N} = Register{M, B, T, N}(copy(state(x)), copy(qubits(x)))

#################
# Batch Iterator
#################

export batch

# batch iterator
struct BatchIter{R <: AbstractRegister}
    reg::R
end

batch(x::AbstractRegister) = BatchIter(x)

import Base: start, next, done, length, eltype

start(x::BatchIter) = 1
next(x::BatchIter, state) =
    view_batch(x.reg, state), state+1
done(x::BatchIter, state) = state > length(x)
length(x::BatchIter{R}) where R = nbatch(x.reg)

export pack!
# permutation and concentration of qubits

"""
    pack!(dst, src, ids)

pack `ids` together to the first k-dimensions.
"""
function pack!(dst, src, ids) end
pack!(reg::AbstractRegister, ids::NTuple) = pack!(reg, reg, ids)
pack!(reg::AbstractRegister, ids::Integer...) = pack!(reg, ids)


export focus

"""
    focus(register, ids...)

pack tensor legs with ids together and reshape the register to
(exposed, remain, batch) or (exposed, remain) depending on register
type (with or without batch).
"""
focus(reg::AbstractRegister, ids...) = focus(reg, ids)

"""
    focus(register, range)

pack tensor legs inside `range` together and reshape the register
to (exposed, remain, batch) or (exposed, remain). range should be
an `UnitRange{Int}` type, which can be declared by colon, e.g

    focus(reg, 2:4)

it will do nothing and return the register directly if the range
start from `1`, e.g

    focus(reg, 1:4)
"""
function focus(src::AbstractRegister{M, B}, range::UnitRange{Int}) where {M, B}
    N = length(range)
    range.start == 1 || return reshape(src, (2^N, 2^(M-N), B))
    focus(src, Tuple(range))
end

function focus(src::AbstractRegister{M, 1}, range::UnitRange{Int}) where M
    N = length(range)
    range.start == 1 || return reshape(src, (2^N, 2^(M-N), B))
    focus(src, Tuple(range))
end

export Register
"""
    Register{M, B, T, N} <: AbstractRegister{M, B, T, N}

default register type. This register use a builtin array
to store the quantum state.
"""
mutable struct Register{M, B, T, N} <: AbstractRegister{M, B, T, N}
    state::Array{T, N}
    ids::Vector{Int}
end

# We store the state with a M-dimentional tensor by default
# This will reduce memory allocation by allowing us use
# permutedims! rather than permutedims.

# Type Inference
Register(nqubit::Int, nbatch::Int, state::Array{T, N}, ids::Vector{Int}) where {T, N} =
    Register{nqubit, nbatch, T, N}(state, ids)
# type conversion
Register(nqubit::Integer, nbatch::Integer, state::Array, ids) =
    Register(Int(nqubit), Int(nbatch), state, Int[ids...])

Register(nqubit::Integer, nbatch::Integer, state::Array) =
    Register(nqubit, nbatch, state, 1:nqubit)

# calculate number of qubits from data array
function Register(nbatch::Integer, state::Array)
    len = length(state) ÷ nbatch
    ispow2(len) || throw(Compat.InexactError(:Register, Register, state))
    Register(log2i(len), nbatch, state)
end

# no batch
Register(state::Array) = Register(1, state)

#########################
# Default Initialization
#########################

# NOTE: we store a rank-n tensor for n qubits by default,
# we can always optimize this by add other kind of
# register for specific tasks
Register(::Type{T}, nqubit::Integer, nbatch::Integer) where T =
    Register(nqubit, nbatch, zeros(T, ntuple(x->2, Val{nqubit})..., nbatch), 1:nqubit)
Register(::Type{T}, nqubit::Integer) where T =
    Register(nqubit, 1, zeros(T, ntuple(x->2, Val{nqubit})...), 1:nqubit)

# We use Compelx128 by default
Register(nqubit::Integer, nbatch::Integer) =
    Register(Complex128, nqubit, nbatch)
Register(nqubit::Integer) =
    Register(Complex128, nqubit)


## Dimension Permutation & Reshape
import Base: reshape

reshape(reg::Register{M, B, T, N}, dims::Dims) where {M, B, T, N} =
    Register(M, B, reshape(state(reg), dims), reg.ids)
reshape!(reg::Register, dims::Dims) = (reshape(reg.data, dims); reg)

function pack!(dst::Register{M, B, T, N}, src::Register{M, B, T, N}, ids::NTuple{K, Int}) where {M, B, T, N, K}
    @assert N == M+1 "register shape mismatch"

    ids = sort!([ids...])
    inds = findin(src.ids, ids)
    perm = copy(src.ids)
    deleteat!(perm, inds)
    prepend!(perm, ids)
    dst.ids .= perm
    append!(perm, M+1)
    permutedims!(state(dst), state(src), perm)
    dst
end

function pack!(dst::Register{M, 1, T, M}, src::Register{M, 1, T, M}, ids::NTuple{K, Int}) where {M, T, K}
    ids = sort!([ids...])
    inds = findin(src.ids, ids)
    perm = copy(src.ids)
    deleteat!(perm, inds)
    prepend!(perm, ids)
    dst.ids .= perm
    permutedims!(state(dst), state(src), perm)
    dst
end

function focus(src::Register{M, B, T, N}, ids::NTuple{K, Int}) where {M, N, B, T, K}
    N == M+1 || (src = reshape(src, ntuple(x->2, Val{M})..., B))

    pack!(src, ids)
    exposed_size = 2^K
    remained_size = 2^(M-K)
    data = reshape(state(src), exposed_size, remained_size, B)
    Register(M, B, data, src.ids)
end

function focus(src::Register{M, 1, T, M}, ids::NTuple{K, Int}) where {M, T, K}
    pack!(src, ids)
    exposed_size = 2^K
    remained_size = 2^(M-K)
    data = reshape(state(src), exposed_size, remained_size)
    Register(M, 1, data, src.ids)
end

focus(src::Register{M, 1}, ids::NTuple) where M =
    focus(reshape(src, ntuple(x->2, Val{M})), ids)
