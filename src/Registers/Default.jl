export DefaultRegister

mutable struct DefaultRegister{B, T} <: AbstractRegister{B, T}
    state::Matrix{T} # this stores a batched state

    function DefaultRegister(raw::Matrix{T}, nbatch::Int=1) where T
        ispow2(size(raw, 1)) && ispow2(size(raw, 2)/nbatch) ||
            throw(Compat.InexactError(:DefaultRegister, DefaultRegister, raw))
        new{nbatch, T}(raw)
    end

    # copy method
    function DefaultRegister(r::DefaultRegister{B, T}) where {B, T}
        new{B, T}(copy(r.state))
    end
end

function DefaultRegister(raw::Vector)
    active_len, remain_len = _len_active_remain(raw, nbatch)
    N = log2i(active_len * remain_len)
    DefaultRegister(raw, N, nbatch)
end

# Required Properties

nqubits(r::DefaultRegister{B}) where B = length(r.state) ÷ B
nactive(r::DefaultRegister) = log2i(size(state(r), 1))
state(r::DefaultRegister) = r.state
statevec(r::DefaultRegister{B}) where B = reshape(r.state, :, B)
statevec(r::DefaultRegister{1}) = reshape(r.state, :)
hypercubic(reg::DefaultRegister{B}) where B = reshape(reg.state, fill(2, nqubits(reg))..., B)
hypercubic(reg::DefaultRegister{1}) = reshape(reg.state, fill(2, nqubits(reg))...)
copy(r::DefaultRegister) = DefaultRegister(r)
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

function similar(r::DefaultRegister{B, T}) where {B, T}
    DefaultRegister(similar(r.state), B)
end

# -> zero_state is an easier interface
zero_state(::Type{T}, n::Int, nbatch::Int=1) = DefaultRegister(zeros(T, 1<<n, nbatch))
rand_state(::Type{T}, n::Int, nbatch::Int=1) = DefaultRegister(zeros(T, 1<<n, nbatch))

for FUNC in [:zero_state, :rand_state]
    @eval FUNC(n::Int, nbatch::Int=1) = FUNC(ComplexF64, n, nbatch)
end

# set default register
function register(raw, nbatch::Int=1)
    register(DefaultRegister, raw, nbatch)
end

# enable multiple dispatch for different initializers
function register(::Type{RT}, ::Type{T}, n::Int, nbatch::Int, method::Symbol) where {RT, T}
    register(Val(method), RT, T, n, nbatch)
end

# config default eltype
register(n::Int, nbatch::Int, method::Symbol) = register(DefaultType, n, nbatch, method)

# shortcuts
#zero_state(n::Int, nbatch::Int=1) = register(n, nbatch, :zero)
#rand_state(n::Int, nbatch::Int=1) = register(n, nbatch, :rand)
#randn_state(n::Int, nbatch::Int=1) = register(n, nbatch, :randn)


#function register(::Val{:rand}, ::Type{<:DefaultRegister}, ::Type{T}, n::Int, nbatch::Int) where T
#    theta = rand(real(T), 1 << n, nbatch)
#    radius = rand(real(T), 1 << n, nbatch)
#    raw = @. radius * exp(im * theta)
#    DefaultRegister(batch_normalize!(raw), nbatch)
#end

#function register(::Val{:randn}, ::Type{<:DefaultRegister}, ::Type{T}, n::Int, nbatch::Int) where T
#    theta = randn(real(T), 1 << n, nbatch)
#    radius = randn(real(T), 1 << n, nbatch)
#    raw = @. radius * exp(im * theta)
#    DefaultRegister(batch_normalize!(raw), nbatch)
#end

#randn_state(n::Int, nbatch::Int=1) = register(n, nbatch, :randn)

# NOTE: we use relative address here
# the input are desired orders of current
# address, not the desired address.
# orders here can be any iterable

##############################################
#            focus! and relax!
##############################################
Ints = Union{Vector{Int}, UnitRange{Int}, Int}
move_ahead(ndim::Int, head::Ints) = vcat(head, setdiff(1:ndim, head))

function group_permutedims(arr::AbstractArray, order::Vector{Int})
    nshape, norder = shapeorder(size(arr), order)
    permutedims(reshape(arr, nshape...), norder)
end

function focus!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = move_ahead(nbit+(B==1 ? 0 : 1), bits)
    reg.state = reshape(group_permutedims(reg |> hypercubic, norder), :, (1<<(nbit-length(bits)))*B)
    reg
end

function relax!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nqubits(reg)
    norder = move_ahead(nbit+(B==1 ? 0 : 1), bits) |> invperm
    reg.state = reshape(group_permutedims(reg |> hypercubic, norder), :, B)
    reg
end

"""
Get the compact shape and order for permutedims.
"""
function shapeorder(shape::NTuple, order::Vector{Int})
    nshape = Int[]
    norder = Int[]
    k_pre = -1
    for k in order
        if k == k_pre+1
            nshape[end] *= shape[k]
        else
            push!(norder, k)
            push!(nshape, shape[k])
        end
        k_pre = k
    end
    invorder = norder |> sortperm
    nshape[invorder], invorder |> invperm
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
