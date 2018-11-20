export DefaultRegister

"""
    DefaultRegister{B, T} <: AbstractRegister{B, T}

Default type for a quantum register. It contains a dense array that represents
a batched quantum state with batch size `B` of type `T`.
"""
mutable struct DefaultRegister{B, T, MT<:AbstractMatrix{T}} <: AbstractRegister{B, T}
    state::MT # this stores a batched state
end

function DefaultRegister{B}(raw::MT) where {B, T, MT<:AbstractMatrix{T}}
    DefaultRegister{B, T, MT}(raw)
end

# copy method
function DefaultRegister(r::DefaultRegister{B}) where B
    DefaultRegister{B}(copy(r.state))
end


# register without batch
"""
    register(raw) -> DefaultRegister

Returns a [`DefaultRegister`](@ref) from a raw dense array (`Vector` or `Matrix`).
"""
function register(raw::AbstractMatrix; B=size(raw,2))
    ispow2(size(raw, 1)) && ispow2(size(raw, 2) ÷ B) ||
        throw(InexactError(:DefaultRegister, DefaultRegister, raw))
    DefaultRegister{B}(raw)
end
register(raw::AbstractVector) = register(reshape(raw, :, 1))

# Required Properties
nqubits(r::DefaultRegister{B}) where B = log2i(length(r.state) ÷ B)
nactive(r::DefaultRegister) = state(r) |> nactive
state(r::DefaultRegister) = r.state

"""
    relaxedvec(r::DefaultRegister) -> AbstractArray

Return a matrix (vector) for B>1 (B=1) as a vector representation of state, with all qubits activated.
"""
relaxedvec(r::DefaultRegister{B}) where B = reshape(r.state, :, B)
relaxedvec(r::DefaultRegister{1}) = vec(r.state)
"""
    statevec(r::DefaultRegister) -> AbstractArray

Return a state matrix/vector by droping the last dimension of size 1.
"""
statevec(r::DefaultRegister) = r.state |> matvec
"""
    hypercubic(r::DefaultRegister) -> AbstractArray

Return the hypercubic form (high dimensional tensor) of this register, only active qubits are considered.
"""
hypercubic(reg::DefaultRegister{B}) where B = reshape(reg.state, ntuple(i->2, Val(nactive(reg)))..., :)
"""
    rank3(reg::DefaultRegister) -> Array{T, 3}

Return the rank 3 tensor representation of state, the 3 dimensions are (activated space, remaining space, batch dimension).
"""
rank3(reg::DefaultRegister{B}) where B = reshape(reg.state, size(reg.state, 1), :, B)

copy(r::DefaultRegister{B}) where B = DefaultRegister{B}(copy(state(r)))
copyto!(reg1::RT, reg2::RT) where {RT<:DefaultRegister} = (copyto!(reg1.state, reg2.state); reg1)

similar(r::DefaultRegister{B, T}) where {B, T} = DefaultRegister{B}(similar(r.state))

"""
    product_state([::Type{T}], n::Int, config::Int, nbatch::Int=1) -> DefaultRegister

a product state on given configuration `config`, e.g. product_state(ComplexF64, 5, 0) will give a zero state on a 5 qubit register.
"""
product_state(::Type{T}, n::Int, config::Integer, nbatch::Int=1) where T = register((arr=zeros(T, 1<<n, nbatch); arr[config+1,:] .= 1; arr))

"""
    zero_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister
"""
zero_state(::Type{T}, n::Int, nbatch::Int=1) where T = product_state(T, n, 0, nbatch)

"""
    rand_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister

here, random complex numbers are generated using `randn(ComplexF64)`.
"""
rand_state(::Type{T}, n::Int, nbatch::Int=1) where T = register(randn(T, 1<<n, nbatch) + im*randn(T, 1<<n, nbatch)) |> normalize!

"""
    uniform_state([::Type{T}], n::Int, nbatch::Int=1) -> DefaultRegister

uniform state, the state after applying H gates on |0> state.
"""
uniform_state(::Type{T}, n::Int, nbatch::Int=1) where T = register(ones(T, 1<<n, nbatch)./sqrt(1<<n))

for FUNC in [:zero_state, :rand_state, :uniform_state]
    @eval $FUNC(n::Int, nbatch::Int=1) = $FUNC(DefaultType, n, nbatch)
end
product_state(n::Int, config::Integer, nbatch::Int=1) = product_state(DefaultType, n, config, nbatch)

function summary(io::IO, r::DefaultRegister{B, T, MT}) where {B, T, MT}
    println(io, "DefaultRegister{", B, ", ", MT, "}")
end

function show(io::IO, r::DefaultRegister{B, T}) where {B, T}
    summary(io, r)
    print(io, "    active qubits: ", nactive(r), "/", nqubits(r))
end

@inline function viewbatch(reg::DefaultRegister, ind::Int)
    st = reg |> rank3
    @inbounds register(view(st, :, :, ind), B=1)
end

function join(reg1::DefaultRegister{B, T1}, reg2::DefaultRegister{B, T2}) where {B, T1, T2}
    s1 = reg1 |> rank3
    s2 = reg2 |> rank3
    T = promote_type(T1, T2)
    state = Array{T,3}(undef, size(s1, 1)*size(s2, 1), size(s1, 2)*size(s2, 2), B)
    for b = 1:B
        @inbounds @views state[:,:,b] = kron(s1[:,:,b], s2[:,:,b])
    end
    DefaultRegister{B}(reshape(state, size(state, 1), :))
end
join(reg1::DefaultRegister{1}, reg2::DefaultRegister{1}) = DefaultRegister{1}(kron(reg1.state, reg2.state))

function addbit!(r::DefaultRegister, n::Int)
    mat = r.state
    M, N = size(mat)
    r.state = similar(r.state, M*(1<<n), N)
    r.state .= 0
    r.state[1:M, :] = mat
    r
end

addbit!(n::Int) = r->addbit!(r, n)

repeat(reg::DefaultRegister{B}, n::Int) where B = DefaultRegister{B*n}(hcat((reg.state for i=1:n)...,))

############ ConjDefaultRegister ##############
const ConjDefaultRegister{B, T, RT} = ConjRegister{B, T, RT} where RT<:DefaultRegister{B, T}

statevec(bra::ConjDefaultRegister) = Adjoint(parent(bra) |> statevec)
relaxedvec(bra::ConjDefaultRegister) = Adjoint(parent(bra) |> relaxedvec)
rank3(bra::ConjDefaultRegister) = Adjoint(parent(bra) |> rank3)
