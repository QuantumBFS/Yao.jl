export DefaultRegister

@inline function _len_active_remain(raw::Matrix, nbatch)
    active_len, nbatch_and_remain = size(raw)
    remain_len = nbatch_and_remain ÷ nbatch
    active_len, remain_len
end

mutable struct DefaultRegister{B, T} <: AbstractRegister{B, T}
    state::Matrix{T} # this stores a batched state
    nqubits::Int # this is the total number of active qubits

    function DefaultRegister(raw::Matrix{T}, nqubits::Int, nbatch::Int) where T
        active_len, remain_len = _len_active_remain(raw, nbatch)

        ispow2(active_len) && ispow2(remain_len) ||
            throw(Compat.InexactError(:DefaultRegister, DefaultRegister, raw))

        new{nbatch, T}(raw, nqubits)
    end

    # copy method
    function DefaultRegister(r::DefaultRegister{B, T}) where {B, T}
        new{B, T}(copy(r.state), nqubits(r))
    end
end

function DefaultRegister(raw::Matrix, nbatch::Int)
    active_len, remain_len = _len_active_remain(raw, nbatch)
    N = log2i(active_len * remain_len)
    DefaultRegister(raw, N, nbatch)
end

#function DefaultRegister(raw::Vector, nbatch::Int)
    #DefaultRegister(repeat(raw, inner=(1, nbatch)), nbatch)
#end

# Required Properties

nqubits(r::DefaultRegister) = r.nqubits
nactive(r::DefaultRegister) = log2i(size(state(r), 1))
state(r::DefaultRegister) = r.state
statevec(r::DefaultRegister{B}) where B = reshape(r.state, 1 << nqubits(r), B)
statevec(r::DefaultRegister{1}) = reshape(r.state, 1 << nqubits(r))
copy(r::DefaultRegister) = DefaultRegister(r)
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

function similar(r::DefaultRegister{B, T}) where {B, T}
    DefaultRegister(similar(r.state), nqubits(r), B)
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

##### super inefficient!
Ints = Union{Vector{Int}, UnitRange{Int}, Int}
function focus!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbit, bits), nbit+1)
    @views reg.state = reshape(permutedims(reshape(reg.state, fill(2, nbit)...,B), norder), :, (1<<(nbit-length(bits)))*B)
    reg
end

function relax!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbit, bits), nbit+1) |> invperm
    @views reg.state = reshape(permutedims(reshape(reg.state, fill(2, nbit)...,B), norder), :, B)
    reg
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
