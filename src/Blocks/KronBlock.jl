export KronBlock


"""
    KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N, T, MT<:MatrixBlock} <: CompositeBlock{N, T}
    slots::Vector{Int}
    addrs::Vector{Int}
    blocks::Vector{MT}

    function KronBlock{N, T}(slots::Vector{Int}, addrs::Vector{Int}, blocks::Vector{MT}) where {N, T, MT<:MatrixBlock}
        new{N, T, MT}(slots, addrs, blocks)
    end

    function KronBlock{N, T}(addrs::Vector{Int}, blocks::Vector{MT}) where {N, T, MT<:MatrixBlock}
        perm = sortperm(addrs)
        permute!(addrs, perm)
        permute!(blocks, perm)
        _assert_addr_safe(N, [i:i+nqubits(b)-1 for (i, b) in zip(addrs, blocks)])

        slots = zeros(Int, N)
        for (i, each) in enumerate(addrs)
            slots[each] = i
        end
        new{N, T, MT}(slots, addrs, blocks)
    end

    function KronBlock{N}(addrs::Vector{Int}, blocks::Vector{<:MatrixBlock}) where N
        T = promote_type([datatype(each) for each in blocks]...)
        KronBlock{N, T}(addrs, blocks)
    end

    function KronBlock{N}(itr::Union{Tuple{Int, <:MatrixBlock}, Pair{Int,<:MatrixBlock}}...) where N
        blocks = MatrixBlock[]
        addrs = Int[]

        for (addr, block) in itr
            push!(addrs, addr)
            push!(blocks, block)
        end
        KronBlock{N}(addrs, blocks)
    end

    function KronBlock(itr::MatrixBlock...)
        N = length(itr)
        KronBlock{N}(collect(1:N), collect(itr))
    end

    KronBlock{N}(args::Union{Tuple, Vector{<:Pair}}) where N = KronBlock{N}(args...)
    KronBlock(args::Union{Tuple, Vector{<:MatrixBlock}}) where N = KronBlock(args...)
end

function copy(k::KronBlock{N, T}) where {N, T}
    slots = copy(k.slots)
    addrs = copy(k.addrs)
    blocks = copy(k.blocks)
    KronBlock{N, T}(slots, addrs, blocks)
end

function similar(k::KronBlock{N, T}) where {N, T}
    slots = zeros(Int, N)
    addrs = empty!(similar(k.addrs))
    blocks = empty!(similar(k.blocks))
    KronBlock{N, T}(slots, addrs, blocks)
end

# some useful interface
addrs(k::KronBlock) = k.addrs
blocks(k::KronBlock) = k.blocks
usedbits(k::KronBlock) = vcat([(i-1).+usedbits(b) for (i, b) in zip(addrs(k), blocks(k))]...)

function getindex(k::KronBlock, addr)
    index = k.slots[addr]
    index == 0 && throw(KeyError(addr))
    k.blocks[index]
end

function setindex!(k::KronBlock, val, addr)
    index = k.slots[addr]
    index == 0 && return _insert_new!(k, val, addr)
    k.blocks[index] = val
end

function _insert_new!(k::KronBlock, val, addr)
    push!(k.addrs, addr)
    push!(k.blocks, val)
    k.slots[addr] = lastindex(k.addrs)
    k
end

# Iterator Protocol
function iterate(k::KronBlock, st = 1)
    if st > length(k)
        nothing
    else
        (k.addrs[st], k.blocks[st]), st + 1
    end
end

eltype(k::KronBlock) = Tuple{Int, MatrixBlock}
length(k::KronBlock) = length(k.blocks)
isunitary(k::KronBlock) = all(isunitary, k.blocks)
ishermitian(k::KronBlock) = all(ishermitian, k.blocks)
isreflexive(k::KronBlock) = all(isreflexive, k.blocks)

###############
eachindex(k::KronBlock) = k.addrs

function mat(k::KronBlock{N}) where N
    sizes = [nqubits(op) for op in blocks(k)]
    start_locs = @. N - $(addrs(k)) - sizes + 1

    order = sortperm(start_locs)
    sorted_start_locs = start_locs[order]
    num_bit_list = vcat(diff(push!(sorted_start_locs, N)) .- sizes[order])

    ⊗ = kron
    reduce(zip(blocks(k)[order], num_bit_list), init=IMatrix(1 << sorted_start_locs[1])) do x, y
        x ⊗ mat(y[1]) ⊗ IMatrix(1<<y[2])
    end
end

adjoint(blk::KronBlock{N, T}) where {N, T} = KronBlock{N, T}(blk.slots, blk.addrs, map(adjoint, blk.blocks))

function cache_key(x::KronBlock)
    [cache_key(each) for each in x.blocks]
end

# NOTE: kronecker blocks are equivalent if its addrs and blocks is the same
function hash(block::KronBlock{N, T}, h::UInt) where {N, T}
    hashkey = hash(objectid(block), h)

    for (addr, block) in block
        hashkey = hash(addr, hashkey)
        hashkey = hash(block, hashkey)
    end
    hashkey
end

function ==(lhs::KronBlock{N, T}, rhs::KronBlock{N, T}) where {N, T}
    all(lhs.addrs .== rhs.addrs) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::KronBlock)
    printstyled(io, "kron"; bold=true, color=color(KronBlock))
end
