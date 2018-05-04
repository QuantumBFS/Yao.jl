"""
    AbstractRegister{N, B, T}

Abstract type for quantum registers, all quantum registers contains a
subtype of `AbstractArray` as member `state`.

## Parameters
- `N` is the number of qubits
- `B` is the batch size
- `T` eltype
"""
abstract type AbstractRegister{N, B, T} end

export nqubit, nbatch, address, state, nactive
# register properties
nqubit(reg::AbstractRegister{N}) where N = N
nbatch(reg::AbstractRegister{N, B}) where {N, B} = B
nactive(reg::AbstractRegister) = log2i(size(state(reg), 1))
# We assume each register has a member named state and orders
# overload this if there is not
address(reg::AbstractRegister{N}) where N = reg.address
state(reg::AbstractRegister) = reg.state

import Base: eltype, copy
eltype(::AbstractRegister{N, B, T}) where {N, B, T} = T
function copy(reg::AbstractRegister) end

# permutation and concentration of qubits

"""
    pack_orders!(reg, orders)

pack `orders` together to the first k-dimensions.
"""
function pack_orders! end


export focus!

"""
    focus!(register, orders)

pack tensor legs with given orders and reshape the register state to
(exposed, remain * batch). `orders` can be a `Vector` or a `Tuple`. It
should contain either a `UnitRange` or `Int`. `UnitRange` will be
considered as a contiguous quantum memory and `Int` will be considered
as an in-contiguous order.
"""
function focus! end

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
    Register{N, B, T} <: AbstractRegister{N, B, T}

default register type. This register use a builtin array
to store the quantum state. The elements inside an instance
of `Register` will be related to a certain memory address,
but since it is not immutable (we need to change its shape),
be careful not to change its state, though the behaviour is
the same, but allocation should be avoided. Therefore, no
shallow copy method is provided.
"""
mutable struct Register{N, B, T} <: AbstractRegister{N, B, T}
    state::Array{T, 2}
    address::Vector{Int}
end

function Register(state::Array{T, 2}) where T
    len, nbatch = size(state)
    ispow2(len) || throw(Compat.InexactError(:Register, Register, state))
    N = log2i(len)
    Register{N, nbatch, T}(state, collect(1:N))
end

Register(state::Array{T, 1}) where T = Register(reshape(state, length(state), 1))

export zero_state, rand_state
zero_state(::Type{T}, nqubit::Int, nbatch::Int=1) where T =
    (state = zeros(T, 1<<nqubit, nbatch); state[1, :] = 1; Register(state))
# TODO: support different RNG?, default is a MT19937
rand_state(::Type{T}, nqubit::Int, nbatch::Int=1) where T = Register(rand(T, 1<<nqubit, nbatch))

# set default type
zero_state(nqubit::Int, nbatch::Int=1) = zero_state(Complex128, nqubit, nbatch)
rand_state(nqubit::Int, nbatch::Int=1) = rand_state(Complex128, nqubit, nbatch)

copy(reg::Register{N, B, T}) where {N, B, T} = Register{N, B, T}(copy(reg.state), copy(reg.address))

## Dimension Permutation
# in-contiguous orders
pack_orders!(reg::Register, orders::Int...) = pack_orders!(reg, orders)
pack_orders!(reg::Register, orders::Vector{Int}) = pack_orders!(reg, Tuple(orders))
pack_orders!(reg::Register, orders::UnitRange{Int}) = pack_orders!(reg, Tuple(orders))

@inline function pack_orders!(reg::Register{N, B}, orders::NTuple{K, Int}) where {N, B, K}
    tensor = reshape(state(reg), ntuple(x->2, Val{N})..., B)
    inds = findin(reg.address, orders)
    perm = reg.address
    deleteat!(perm, inds)
    prepend!(perm, orders)
    permutedims!(tensor, tensor, (perm..., N+1))
    reg
end

# contiguous orders
# TODO: add exception when UnitRange is not actually contiguous
# NOTE: remove this if merge legs together is not faster than original
# @inline function pack_orders!(reg::Register{N, B}, orders::UnitRange{Int}) where {N, B}
#     start_order = first(orders)
#     # return ASAP when target order at the beginning
#     start_order == first(address(reg)) && return reg

#     pack_size = 1<<length(orders)
#     start_ind, = findin(address(reg), start_order)

#     if start_ind+length(orders)-1 == N
#         src = reshape(state(reg), :, pack_size)
#         dst = reshape(state(reg), pack_size, :)
#         transpose!(dst, src)
#     else
#         src = reshape(state(reg), 1<<start_ind, pack_size, :)
#         dst = reshape(state(reg), pack_size, 1<<start_ind, :)
#         permutedims!(dst, src, [2, 1, 3])
#     end
#     deleteat!(reg.address, start_ind:(start_ind + length(orders) - 1))
#     prepend!(reg.address, collect(orders))
#     reg
# end

# mixed
@inline function pack_orders!(reg::Register, orders)
    for each in reverse(orders)
        pack_orders!(reg, each)
    end
    reg
end

nexposed(orders::NTuple{K, Int}) where K = 1<<K
nexposed(orders::Vector{Int}) = 1<<length(orders)
nexposed(orders::UnitRange{Int}) = 1<<length(orders)
# mixed
nexposed(orders...) = nexposed(orders)
function nexposed(orders)
    total = 0
    for each in orders
        total += length(each)
    end
    1<<total
end

function focus!(reg::Register{N, B}, orders...) where {N, B}
    pack_orders!(reg, orders)
    reg.state = reshape(state(reg), (nexposed(orders...), :))
    reg
end

import Base: show

function show(io::IO, reg::Register{N, B, T}) where {N, B, T}
    println(io, "Default Register (CPU, $T):")
    println(io, "    total: ", N)
    println(io, "    batch: ", B)
    print(io, "    active: ", nactive(reg))
end
