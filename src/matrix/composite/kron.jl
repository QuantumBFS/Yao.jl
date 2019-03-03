using YaoBase
export KronBlock, kron

"""
    KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}
    slots::Vector{Int}
    addrs::Vector{Int}
    blocks::Vector{MT}
end

KronBlock{N, T}(slots::Vector{Int}, addrs::Vector{Int}, blocks::Vector{MT}) where {N, T, MT <: MatrixBlock} =
    KronBlock{N, T, MT}(slots, addrs, blocks)

function KronBlock{N, T}(addrs::Vector{Int}, blocks::Vector{MT}) where {N, T, MT<:MatrixBlock}
    perm = sortperm(addrs)
    permute!(addrs, perm)
    permute!(blocks, perm)
    @assert_addrs N collect(i:i+nqubits(b)-1 for (i, b) in zip(addrs, blocks))

    slots = zeros(Int, N)
    for (i, each) in enumerate(addrs)
        slots[each] = i
    end
    return KronBlock{N, T, MT}(slots, addrs, blocks)
end

function KronBlock{N}(addrs::Vector{Int}, blocks::Vector{<:MatrixBlock}) where N
    T = promote_type([datatype(each) for each in blocks]...)
    return KronBlock{N, T}(addrs, blocks)
end

function KronBlock{N}(itr::Union{Tuple{Int, <:MatrixBlock}, Pair{Int,<:MatrixBlock}}...) where N
    blocks = MatrixBlock[]
    addrs = Int[]

    for (addr, block) in itr
        push!(addrs, addr)
        push!(blocks, block)
    end
    return KronBlock{N}(addrs, blocks)
end

function KronBlock(itr::MatrixBlock...)
    N = length(itr)
    return KronBlock{N}(collect(1:N), collect(itr))
end

KronBlock{N}(args::Union{Tuple, Vector{<:Pair}}) where N = KronBlock{N}(args...)
KronBlock(args::Union{Tuple, Vector{<:MatrixBlock}}) where N = KronBlock(args...)
KronBlock(blk::KronBlock) = copy(blk)

"""
    kron(n, blocks::Pair{Int, <:MatrixBlock}...)

Return a [`KronBlock`](@ref), with total number of qubits `n` and pairs of blocks.

# Example
"""
Base.kron(total::Int, blocks::Pair{Int, <:MatrixBlock}...,) = KronBlock{total}(blocks...,)

"""
    kron(n, blocks::MatrixBlock...)
    kron(n, itr)

Return a [`KronBlock`](@ref), with total number of qubits `n`, and `blocks` should use all
the locations on `n` wires in quantum circuits.
"""
function Base.kron(total::Int, blocks::MatrixBlock...,)
    sum(nqubits, blocks) == total || throw(AddressConflictError("Size of blocks does not match total size."))
    return KronBlock(blocks)
end

Base.kron(total::Int, blocks::Base.Generator) = kron(total, blocks...)

"""
    kron(blocks...) -> f(n)
    kron(itr) -> f(n)

Return a lambda, which will take the total number of qubits as input.

# Example
"""
Base.kron(blocks::MatrixBlock...,) = @λ(n->kron(n, blocks...))
Base.kron(blocks::Pair{Int, <:MatrixBlock}...,) = @λ(n->kron(n, blocks...))
Base.kron(blocks::Base.Generator) = @λ(n->kron(n, blocks))

OccupiedLocations(k::KronBlock) = Iterators.flatten(map(x-> x + i - 1, OccupiedLocations(b)) for (i, b) in zip(k.addrs, subblocks(k)))
subblocks(x::KronBlock) = SubBlockIt(x.blocks)
chsubblocks(pb::KronBlock{N}, blocks) where N = KronBlock{N}(pb.addrs, blocks)
cache_key(x::KronBlock) = [cache_key(each) for each in x.blocks]
color(::Type{T}) where {T <: KronBlock} = :cyan


function mat(k::KronBlock{N}) where N
    sizes = map(nqubits, subblocks(k))
    start_locs = @. N - $(k.addrs) - sizes + 1

    order = sortperm(start_locs)
    sorted_start_locs = start_locs[order]
    num_bit_list = vcat(diff(push!(sorted_start_locs, N)) .- sizes[order])

    return reduce(zip(subblocks(k)[order], num_bit_list), init=IMatrix(1 << sorted_start_locs[1])) do x, y
        kron(x, mat(y[1]), IMatrix(1<<y[2]))
    end
end

function Base.copy(k::KronBlock{N, T}) where {N, T}
    slots = copy(k.slots)
    addrs = copy(k.addrs)
    blocks = copy(k.blocks)
    return KronBlock{N, T}(slots, addrs, blocks)
end

function Base.similar(k::KronBlock{N, T}) where {N, T}
    slots = zeros(Int, N)
    addrs = empty!(similar(k.addrs))
    blocks = empty!(similar(k.blocks))
    return KronBlock{N, T}(slots, addrs, blocks)
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
    push!(k.addrs, addr)
    push!(k.blocks, val)
    k.slots[addr] = lastindex(k.addrs)
    return k
end

function Base.iterate(k::KronBlock, st = 1)
    if st > length(k)
        return nothing
    else
        return (k.addrs[st], k.blocks[st]), st + 1
    end
end

Base.eltype(k::KronBlock) = Tuple{Int, MatrixBlock}
Base.length(k::KronBlock) = length(k.blocks)
Base.eachindex(k::KronBlock) = k.addrs

function Base.:(==)(lhs::KronBlock{N, T}, rhs::KronBlock{N, T}) where {N, T}
    return all(lhs.addrs .== rhs.addrs) && all(lhs.blocks .== rhs.blocks)
end

Base.adjoint(blk::KronBlock{N, T}) where {N, T} = KronBlock{N, T}(blk.slots, blk.addrs, map(adjoint, blk.blocks))

YaoBase.ishermitian(k::KronBlock) = all(ishermitian, k.blocks) || ishermitian(mat(k))
YaoBase.isunitary(k::KronBlock) = all(isunitary, k.blocks) || isunitary(mat(k))
YaoBase.isreflexive(k::KronBlock) = all(isreflexive, k.blocks) || isreflexive(mat(k))
