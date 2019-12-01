using YaoBase
export KronBlock, kron

"""
    KronBlock{N, T, MT<:AbstractBlock} <: CompositeBlock{N, T}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N,MT<:AbstractBlock} <: CompositeBlock{N}
    slots::Vector{Int}
    locs::Vector{Int}
    blocks::Vector{MT}
end

KronBlock{N}(slots::Vector{Int}, locs::Vector{Int}, blocks::Vector{MT}) where {N,MT<:AbstractBlock} =
    KronBlock{N,MT}(slots, locs, blocks)

function KronBlock{N}(locs::Vector{Int}, blocks::Vector{MT}) where {N,MT<:AbstractBlock}
    perm = sortperm(locs)
    permute!(locs, perm)
    permute!(blocks, perm)
    @assert_locs_safe N collect(i:i+nqubits(b)-1 for (i, b) in zip(locs, blocks))

    slots = zeros(Int, N)
    for (i, each) in enumerate(locs)
        slots[each] = i
    end
    return KronBlock{N,MT}(slots, locs, blocks)
end

function KronBlock{N}(itr::Pair{Int,<:AbstractBlock}...) where {N}
    blocks = AbstractBlock[]
    locs = Int[]

    for (addr, block) in itr
        push!(locs, addr)
        push!(blocks, block)
    end
    return KronBlock{N}(locs, blocks)
end

function KronBlock(itr::AbstractBlock...)
    N = sum(nqubits, itr)
    locs = Int[]
    count = 1
    for each in itr
        push!(locs, count)
        count += nqubits(each)
    end
    return KronBlock{N}(locs, collect(itr))
end

KronBlock(blk::KronBlock) = copy(blk)

"""
    kron(n, blocks::Pair{Int, <:AbstractBlock}...)

Return a [`KronBlock`](@ref), with total number of qubits `n` and pairs of blocks.

# Example

Use `kron` to construct a `KronBlock`, it will put an `X` gate on the `1`st qubit,
and a `Y` gate on the `3`rd qubit.

```jldoctest; setup=:(using YaoBlocks)
julia> kron(4, 1=>X, 3=>Y)
nqubits: 4
kron
├─ 1=>X gate
└─ 3=>Y gate

```
"""
Base.kron(total::Int, blocks::Pair{Int,<:AbstractBlock}...) = KronBlock{total}(blocks...)

"""
    kron(blocks::AbstractBlock...)
    kron(n, itr)

Return a [`KronBlock`](@ref), with total number of qubits `n`, and `blocks` should use all
the locations on `n` wires in quantum circuits.

# Example

You can use kronecker product to composite small blocks to a large blocks.

```jldoctest; setup=:(using YaoBlocks)
julia> kron(X, Y, Z, Z)
nqubits: 4
kron
├─ 1=>X gate
├─ 2=>Y gate
├─ 3=>Z gate
└─ 4=>Z gate

```
"""
Base.kron(blocks::AbstractBlock...) = KronBlock(blocks...)
Base.kron(fs::Union{Function,AbstractBlock}...) = @λ(n -> kron(n, fs...))

function Base.kron(total::Int, blocks::AbstractBlock...)
    sum(nqubits, blocks) == total || error("total number of qubits mismatch")
    return kron(blocks...)
end

Base.kron(total::Int, blocks::Union{AbstractBlock,Pair}...) =
    error("location of sparse distributed blocks must be explicit declared with pair (e.g 2=>X)")

Base.kron(total::Int, blocks::Base.Generator) = kron(total, blocks...)

"""
    kron(blocks...) -> f(n)
    kron(itr) -> f(n)

Return a lambda, which will take the total number of qubits as input.

# Example

If you don't know the number of qubit yet, or you are just too lazy, it is fine.

```jldoctest; setup=:(using YaoBlocks)
julia> kron(put(1=>X) for _ in 1:2)
(n -> kron(n, (n  ->  put(n, 1 => X gate)), (n  ->  put(n, 1 => X gate))))

julia> kron(X for _ in 1:2)
nqubits: 2
kron
├─ 1=>X gate
└─ 2=>X gate

julia> kron(1=>X, 3=>Y)
(n -> kron(n, 1 => X gate, 3 => Y gate))
```
"""
Base.kron(blocks::Pair{Int,<:AbstractBlock}...) = @λ(n -> kron(n, blocks...))
Base.kron(blocks::Base.Generator) = kron(blocks...)

occupied_locs(k::KronBlock) = (
    Iterators.flatten(
        map(x -> x + i - 1, occupied_locs(b)) for (i, b) in zip(k.locs, subblocks(k))
    )...,
)
subblocks(x::KronBlock) = x.blocks
chsubblocks(pb::KronBlock{N}, it) where {N} = KronBlock{N}(pb.locs, collect(it))
cache_key(x::KronBlock) = [cache_key(each) for each in x.blocks]
color(::Type{T}) where {T<:KronBlock} = :cyan

function _prepair_kronmat(k::KronBlock{N}) where {N}
    sizes = map(nqubits, subblocks(k))
    start_locs = @. N - $(k.locs) - sizes + 1

    order = sortperm(start_locs)
    sorted_start_locs = start_locs[order]
    num_bit_list = vcat(diff(push!(sorted_start_locs, N)) .- sizes[order])
    return order, num_bit_list, sorted_start_locs
end

function mat(::Type{T}, k::KronBlock{N}) where {T,N}
    order, num_bit_list, sorted_start_locs = _prepair_kronmat(k)
    blocks = subblocks(k)[order]
    return reduce(zip(blocks, num_bit_list), init = IMatrix{1 << sorted_start_locs[1],T}()) do x, y
        kron(x, mat(T, y[1]), IMatrix(1 << y[2]))
    end
end

function apply!(r::AbstractRegister, k::KronBlock)
    _check_size(r, k)
    for (locs, block) in zip(k.locs, k.blocks)
        _instruct!(r, block, Tuple(locs:locs+nqubits(block)-1))
    end
    return r
end

_instruct!(reg::AbstractRegister, block::AbstractBlock, locs) =
    instruct!(reg, mat_matchreg(reg, block), locs)

# specialization
for G in [:X, :Y, :Z, :T, :S, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval _instruct!(reg::AbstractRegister, block::$GT, locs) =
        instruct!(reg, Val($(QuoteNode(G))), locs)
end

function Base.copy(k::KronBlock{N}) where {N}
    slots = copy(k.slots)
    locs = copy(k.locs)
    blocks = copy(k.blocks)
    return KronBlock{N}(slots, locs, blocks)
end

function Base.similar(k::KronBlock{N}) where {N}
    slots = zeros(Int, N)
    locs = empty!(similar(k.locs))
    blocks = empty!(similar(k.blocks))
    return KronBlock{N}(slots, locs, blocks)
end

function Base.getindex(k::KronBlock, addr)
    index = k.slots[addr]
    index == 0 && throw(KeyError(addr))
    return k.blocks[index]
end

function Base.setindex!(k::KronBlock, val, addr)
    index = k.slots[addr]
    index == 0 && return _insert_new!(k, val, addr)
    k.blocks[index] = val
    return k
end

function _insert_new!(k::KronBlock, val, addr)
    push!(k.locs, addr)
    push!(k.blocks, val)
    k.slots[addr] = lastindex(k.locs)
    return k
end

function Base.iterate(k::KronBlock, st = 1)
    if st > length(k)
        return nothing
    else
        return (k.locs[st], k.blocks[st]), st + 1
    end
end

Base.eltype(k::KronBlock) = Tuple{Int,AbstractBlock}
Base.length(k::KronBlock) = length(k.blocks)
Base.eachindex(k::KronBlock) = k.locs

function Base.:(==)(lhs::KronBlock{N}, rhs::KronBlock{N}) where {N}
    return all(lhs.locs .== rhs.locs) && all(lhs.blocks .== rhs.blocks)
end

Base.adjoint(blk::KronBlock{N}) where {N} =
    KronBlock{N}(blk.slots, blk.locs, map(adjoint, blk.blocks))

YaoBase.ishermitian(k::KronBlock) = all(ishermitian, k.blocks) || ishermitian(mat(k))
YaoBase.isunitary(k::KronBlock) = all(isunitary, k.blocks) || isunitary(mat(k))
YaoBase.isreflexive(k::KronBlock) = all(isreflexive, k.blocks) || isreflexive(mat(k))
