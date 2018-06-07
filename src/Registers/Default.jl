export DefaultRegister

@inline function _len_active_remain(raw::Matrix, nbatch)
    active_len, nbatch_and_remain = size(raw)
    remain_len = nbatch_and_remain ÷ nbatch
    active_len, remain_len
end

mutable struct DefaultRegister{B, T} <: AbstractRegister{B, T}
    state::Matrix{T} # this stores a batched state

    nactive::Int # this is the total number of active qubits
    # NOTE: we should replace this with a static mutable vector in the future
    address::Vector{Int} # this indicates the absolute address of each qubit

    function DefaultRegister(raw::Matrix{T}, address::Vector{Int}, nactive::Int, nbatch::Int) where T
        active_len, remain_len = _len_active_remain(raw, nbatch)

        ispow2(active_len) && ispow2(remain_len) ||
            throw(Compat.InexactError(:DefaultRegister, DefaultRegister, raw))

        new{nbatch, T}(raw, nactive, address)
    end

    # copy method
    function DefaultRegister(r::DefaultRegister{B, T}) where {B, T}
        new{B, T}(copy(r.state), r.nactive, copy(r.address))
    end
end

function DefaultRegister(raw::Matrix, nbatch::Int)
    active_len, remain_len = _len_active_remain(raw, nbatch)
    N = log2i(active_len * remain_len)
    DefaultRegister(raw, collect(0x1:N), N, nbatch)
end

function DefaultRegister(raw::Vector, nbatch::Int)
    DefaultRegister(repeat(raw, inner=(1, nbatch)), nbatch)
end

# Required Properties

nqubits(r::DefaultRegister) = length(r.address)
nactive(r::DefaultRegister) = r.nactive
address(r::DefaultRegister) = r.address
state(r::DefaultRegister) = r.state
statevec(r::DefaultRegister{B}) where B = reshape(r.state, 1 << nqubits(r), B)
statevec(r::DefaultRegister{1}) = reshape(r.state, 1 << nqubits(r))
copy(r::DefaultRegister) = DefaultRegister(r)
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

function similar(r::DefaultRegister{B, T}) where {B, T}
    DefaultRegister(similar(r.state), copy(r.address), r.nactive, B)
end

# factory methods
register(::Type{<:DefaultRegister}, raw, nbatch::Int) = DefaultRegister(raw, nbatch)

function register(::Val{:zero}, ::Type{<:DefaultRegister}, ::Type{T}, n::Int, nbatch::Int) where T
    raw = zeros(T, 1 << n, nbatch)
    raw[1, :] .= 1
    DefaultRegister(raw, nbatch)
end

function register(::Val{:rand}, ::Type{<:DefaultRegister}, ::Type{T}, n::Int, nbatch::Int) where T
    theta = rand(real(T), 1 << n, nbatch)
    radius = rand(real(T), 1 << n, nbatch)
    raw = @. radius * exp(im * theta)
    DefaultRegister(batch_normalize!(raw), nbatch)
end

function register(::Val{:randn}, ::Type{<:DefaultRegister}, ::Type{T}, n::Int, nbatch::Int) where T
    theta = randn(real(T), 1 << n, nbatch)
    radius = randn(real(T), 1 << n, nbatch)
    raw = @. radius * exp(im * theta)
    DefaultRegister(batch_normalize!(raw), nbatch)
end

# NOTE: we use relative address here
# the input are desired orders of current
# address, not the desired address.
# orders here can be any iterable

function get_configs(total, range...)
    r = collect(range)
    p = sortperm(r, by=x->first(x))
    ip = sortperm(p)
    sorted = r[p]

    src_shape = Int[]
    perm_head, perm_tail = Int[], Int[]
    prev = 1; count = 1; nactive = 0;
    for each in sorted
        if first(each) - prev != 0
            push!(src_shape, first(each) - prev)
            push!(perm_tail, count)
            count += 1
        end

        nactive += length(each)
        push!(src_shape, length(each))
        push!(perm_head, count)
        count += 1
        prev = last(each) + 1
    end
    perm = append!(perm_head[ip], perm_tail)

    last_interval = total - last(last(sorted))
    if last_interval != 0
        push!(src_shape, last_interval)
        push!(perm, count)
    end

    dst_shape = src_shape[perm]
    src_shape, dst_shape, perm, nactive
end

const RangeType = Union{Int, UnitRange}

function focus!(r::DefaultRegister{B}, range::RangeType...) where B
    total = nqubits(r)
    src_shape, dst_shape, perm, r.nactive = get_configs(total, range...)

    map!(x->(1<<x), src_shape, src_shape)
    map!(x->(1<<x), dst_shape, dst_shape)
    push!(src_shape, B)
    push!(dst_shape, B)

    src = reshape(r.state, src_shape...)
    dst = reshape(r.state, dst_shape...)

    # permute state
    push!(perm, length(perm) + 1)
    permutedims!(dst, src, perm)

    # permute address
    expand_range = [i for each in range for i in each]
    perm = collect(1:total)
    inds = findall(in(expand_range), perm)
    deleteat!(perm, inds)
    prepend!(perm, expand_range)
    permute!(r.address, perm)

    r.state = reshape(r.state, 1 << r.nactive, (1 << (total - r.nactive)) * B)
    r
end

# we convert state to a vector to use
# intrincs like gemv, when nremain is
# 0 and the state is actually a vector
function *(op, r::DefaultRegister{1})
    if nremain(r) == 0
        return op * vec(r.state)
    end
    op * r.state
end

function *(op, r::DefaultRegister)
    op * r.state
end

import Base: summary
@static if VERSION < v"0.7-"
    function summary(r::DefaultRegister{B, T}) where {B, T}
        "DefaultRegister{$B, $T}\n"
    end

    function show(io::IO, r::DefaultRegister{B, T}) where {B, T}
        print(io, summary(r))
        print(io, "    active qubits: ", nactive(r), "/", nqubits(r))
    end

else
    function summary(io::IO, r::DefaultRegister{B, T}) where {B, T}
        println(io, "DefaultRegister{", B, ", ", T, "}")
    end

    function show(io::IO, r::DefaultRegister{B, T}) where {B, T}
        summary(io, r)
        print(io, "    active qubits: ", nactive(r), "/", nqubits(r))
    end
end
