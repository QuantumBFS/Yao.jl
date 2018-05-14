@inline function _len_active_remain(raw::Matrix, nbatch)
    active_len, nbatch_and_remain = size(raw)
    remain_len = nbatch_and_remain ÷ nbatch
    active_len, remain_len
end

mutable struct Register{B, T} <: AbstractRegister{B, T}
    state::Matrix{T} # this stores a batched state

    nactive::Int # this is the total number of active qubits
    # NOTE: we should replace this with a static mutable vector in the future
    address::Vector{UInt} # this indicates the absolute address of each qubit

    function Register(raw::Matrix{T}, address::Vector{UInt}, nactive::UInt, nbatch::UInt) where T
        active_len, remain_len = _len_active_remain(raw, nbatch)

        ispow2(active_len) && ispow2(remain_len) ||
            throw(Compat.InexactError(:Register, Register, raw))

        new{nbatch, T}(raw, nactive, address)
    end

    # copy method
    function Register(r::Register{B, T}) where {B, T}
        new{B, T}(copy(r.state), r.nactive, copy(r.address))
    end
end

function Register(raw::Matrix, nbatch::UInt)
    active_len, remain_len = _len_active_remain(raw, nbatch)
    N = unsigned(log2i(active_len * remain_len))
    Register(raw, collect(0x1:N), N, nbatch)
end

function Register(raw::Vector, nbatch::UInt)
    Register(reshape(raw, length(raw), 1), nbatch)
end

# Required Properties

nqubit(r::Register) = length(r.address)
nactive(r::Register) = r.nactive
address(r::Register) = r.address
state(r::Register) = r.state
copy(r::Register) = Register(r)

function similar(r::Register{B, T}) where {B, T}
    Register(similar(r.state), copy(r.address), r.nactive, B)
end

# factory methods
register(::Type{Register}, raw, nbatch::UInt) = Register(raw, nbatch)

function register(::Type{InitMethod{:zero}}, ::Type{Register}, ::Type{T}, n::Int, nbatch::UInt) where T
    raw = zeros(T, 1 << n, nbatch)
    raw[1, :] = 1
    Register(raw, nbatch)
end

function register(::Type{InitMethod{:rand}}, ::Type{Register}, ::Type{T}, n::Int, nbatch::UInt) where T
    theta = rand(real(T), 1 << n, nbatch)
    radius = rand(real(T), 1 << n, nbatch)
    raw = @. radius * exp(im * theta)
    Register(batch_normalize!(raw), nbatch)
end

function register(::Type{InitMethod{:randn}}, ::Type{Register}, ::Type{T}, n::Int, nbatch::UInt) where T
    theta = randn(real(T), 1 << n, nbatch)
    radius = randn(real(T), 1 << n, nbatch)
    raw = @. radius * exp(im * theta)
    Register(batch_normalize!(raw), nbatch)
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

    src_shape, dst_shape = Int[], Int[]
    perm_head, perm_tail = Int[], Int[]
    prev = 1; count = 1; nactive = 0;
    for each in sorted
        if first(each) - prev != 0
            push!(src_shape, first(each) - prev)
            push!(dst_shape, first(each) - prev)
            push!(perm_tail, count)
            count += 1
        end

        nactive += length(each)
        push!(src_shape, length(each))
        prepend!(dst_shape, length(each))
        push!(perm_head, count)
        count += 1
        prev = last(each) + 1
    end
    perm = append!(perm_head[ip], perm_tail)

    last_interval = total - last(last(sorted))
    if last_interval != 0
        push!(src_shape, last_interval)
        push!(dst_shape, last_interval)
        push!(perm, count)
    end

    src_shape, dst_shape, perm, nactive
end

function focus!(r::Register{B}, range...) where B
    total = nqubit(r)
    src_shape, dst_shape, perm, r.nactive = get_configs(total, range...)

    map!(x->(1<<x), src_shape, src_shape)
    map!(x->(1<<x), dst_shape, dst_shape)
    push!(src_shape, B)
    push!(dst_shape, B)

    src = reshape(r.state, src_shape...)
    dst = reshape(r.state, dst_shape...)

    index = 1
    expand_range = [i for each in range for i in each]
    inds = findin(r.address, expand_range)
    deleteat!(r.address, inds)
    prepend!(r.address, expand_range)

    push!(perm, length(perm) + 1)
    permutedims!(dst, src, perm)

    r.state = reshape(r.state, 1 << r.nactive, (1 << (total - r.nactive)) * Int(B))
    r
end

# we convert state to a vector to use
# intrincs like gemv, when nremain is
# 0 and the state is actually a vector
function *(op, r::Register{1})
    if nremain(r) == 0
        return op * vec(r.state)
    end
    op * r.state
end

function *(op, r::Register)
    op * r.state
end

function show(io::IO, r::Register{B, T}) where {B, T}
    println(io, "Default Register (CPU, $T):")
    println(io, "    total: ", nqubit(r))
    println(io, "    batch: ", B)
    print(io, "    active: ", nactive(r))
end
