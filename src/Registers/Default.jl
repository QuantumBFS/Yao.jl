export DefaultRegister


"""
    DefaultRegister{B, T} <: AbstractRegister{B, T}

Default type for a quantum register. It contains a dense array that represents
a batched quantum state with batch size `B` of type `T`.
"""
mutable struct DefaultRegister{B, T} <: AbstractRegister{B, T}
    state::Matrix{T} # this stores a batched state

    function DefaultRegister{B, T}(raw::Matrix{T}) where {B, T}
        ispow2(size(raw, 1)) && ispow2(size(raw, 2) ÷ B) ||
            throw(Compat.InexactError(:DefaultRegister, DefaultRegister, raw))
        new{B, T}(raw)
    end

    # copy method
    function DefaultRegister(r::DefaultRegister{B, T}) where {B, T}
        new{B, T}(copy(r.state))
    end
end

DefaultRegister{B}(raw::Matrix{T}) where {B, T} = DefaultRegister{B, T}(raw)

# register without batch
"""
    register(raw) -> DefaultRegister

Returns a [`DefaultRegister`](@ref) from a raw dense array (`Vector` or `Matrix`).
"""
register(raw::Vector) = DefaultRegister{1}(reshape(raw, :, 1))
register(raw::Matrix) = DefaultRegister{size(raw, 2)}(raw)

# Required Properties

nqubits(r::DefaultRegister{B}) where B = log2i(length(r.state) ÷ B)
nactive(r::DefaultRegister) = state(r) |> nqubits
state(r::DefaultRegister) = r.state
statevec(r::DefaultRegister{B}) where B = reshape(r.state, :, B)
statevec(r::DefaultRegister{1}) = vec(r.state)
hypercubic(reg::DefaultRegister{B}) where B = reshape(reg.state, fill(2, nactive(reg))..., :)
copy(r::DefaultRegister{B}) where B = DefaultRegister{B}(copy(state(r)))
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

similar(r::DefaultRegister{B, T}) where {B, T} = DefaultRegister{B}(similar(r.state))

# -> zero_state is an easier interface
zero_state(::Type{T}, n::Int, nbatch::Int=1) where T = register((arr=zeros(T, 1<<n, nbatch); arr[1,:]=1; arr))
rand_state(::Type{T}, n::Int, nbatch::Int=1) where T = register(randn(T, 1<<n, nbatch) + im*randn(T, 1<<n, nbatch)) |> normalize!

for FUNC in [:zero_state, :rand_state]
    @eval $FUNC(n::Int, nbatch::Int=1) = $FUNC(DefaultType, n, nbatch)
end

function probs(r::DefaultRegister{1})
    if size(r.state, 2) == 1
        return vec(r.state .|> abs2)
    else
        return squeeze(sum(r.state .|> abs2, 2), 2)
    end
end

function probs(r::DefaultRegister{B}) where B
    if size(r.state, 2) == B
        return r.state .|> abs2
    else
        probs = reshape(r.state .|> abs2, size(r.state, 1), :, B)
        return squeeze(sum(probs, 2), 2)
    end
end

#############################################
#            focus! and relax!
##############################################
Ints = Union{Vector{Int}, UnitRange{Int}, Int, NTuple}
move_ahead(ndim::Int, head::Ints) = vcat(head, setdiff(1:ndim, head))

function group_permutedims(arr::AbstractArray, order::Vector{Int})
    nshape, norder = shapeorder(size(arr), order)
    permutedims(reshape(arr, nshape...), norder)
end

function focus!(reg::DefaultRegister{B}, bits::Ints) where B
    nbit = nactive(reg)
    if all(bits .== 1:length(bits))
        arr = reg.state
    else
        norder = move_ahead(nbit+1, bits)
        arr = group_permutedims(reg |> hypercubic, norder)
    end
    reg.state = reshape(arr, :, (1<<(nbit-length(bits)))*B)
    reg
end

function relax!(reg::DefaultRegister{B}, bits::Ints, nbit::Int=nqubits(reg)) where B
    reg.state = reshape(reg.state, 1<<nbit, :)
    if any(bits .!= 1:length(bits))
        norder = move_ahead(nbit+1, bits) |> invperm
        reg.state = reshape(group_permutedims(reg |> hypercubic, norder), 1<<nbit, :)
    end
    reg
end

relax!(reg::DefaultRegister, nbit::Int=nqubits(reg)) = relax!(reg, Int[], nbit)
isnormalized(reg::DefaultRegister) = all(sum(copy(reg) |> relax! |> probs, 1) .≈ 1)

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
