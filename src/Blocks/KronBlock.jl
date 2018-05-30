export KronBlock

"""
    KronBlock{N, T} <: CompositeBlock

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N, T} <: CompositeBlock{N, T}
    slots::Vector{Int}
    addrs::Vector{Int}
    blocks::Vector{MatrixBlock}

    function KronBlock{N, T}(slots::Vector{Int}, addrs::Vector{Int}, blocks::Vector) where {N, T}
        new{N, T}(slots, addrs, blocks)
    end

    function KronBlock{N, T}(addrs::Vector, blocks::Vector) where {N, T}
        perm = sortperm(addrs)
        permute!(addrs, perm)
        permute!(blocks, perm)

        slots = zeros(Int, N)
        for (i, each) in enumerate(addrs)
            slots[each] = i
        end
        new{N, T}(slots, addrs, blocks)
    end

    function KronBlock{N}(addrs::Vector, blocks::Vector) where N
        T = promote_type([datatype(each) for each in blocks]...)
        KronBlock{N, T}(addrs, blocks)
    end

    function KronBlock{N}(args...) where N
        KronBlock{N}(args)
    end

    function KronBlock{N}(arg::T) where {N, MT <: MatrixBlock, T <: Union{Pair{Int, MT}, MT}}
        KronBlock{N}([arg])
    end

    function KronBlock{N}(itr) where N
        curr_head = 1
        blocks = MatrixBlock[]
        addrs = Int[]

        for each in itr
            if isa(each, MatrixBlock)
                push!(blocks, each)
                push!(addrs, curr_head)
                curr_head += nqubits(each)
            elseif isa(each, Union{Tuple, Pair})
                curr_head, block = each
                push!(addrs, curr_head)
                push!(blocks, block)
                curr_head += nqubits(block)
            else
                throw(MethodError(KronBlock, itr))
            end
        end

        KronBlock{N}(addrs, blocks)
    end
end

function copy(k::KronBlock{N, T}) where {N, T}
    slots = copy(k.slots)
    addrs = copy(k.addrs)
    blocks = [copy(each) for each in k.blocks]
    KronBlock{N, T}(slots, addrs, blocks)
end

function similar(k::KronBlock{N, T}) where {N, T}
    slots = zeros(Int, N)
    addrs = empty!(similar(k.addrs))
    blocks = empty!(similar(k.blocks))
    KronBlock{N, T}(slots, addrs, blocks)
end

# some useful interface
export addrs
addrs(k::KronBlock) = k.addrs
blocks(k::KronBlock) = k.blocks

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
    k.slots[addr] = endof(k.addrs)
    k
end

# Iterator Protocol

start(k::KronBlock) = 1
function next(k::KronBlock, st)
    (k.addrs[st], k.blocks[st]), st + 1
end

done(k::KronBlock, st) = st > length(k)
eltype(k::KronBlock) = Tuple{Int, MatrixBlock}
length(k::KronBlock) = length(k.blocks)

###############
eachindex(k::KronBlock) = k.addrs

function mat(k::KronBlock{N, T}) where {N, T}
    curr_addr = 1
    first_block = first(k.blocks)
    first_addr = first(k.addrs)

    if curr_addr == first_addr
        curr_addr += nqubits(first_block)
        op = mat(first_block)
    else
        op = kron(mat(first_block), speye(T, 1 << (first_addr - curr_addr)))
        curr_addr = first_addr + nqubits(first_block)
    end

    for count = 2:length(k.addrs)
        next_addr = k.addrs[count]
        next_block = k.blocks[count]
        if curr_addr != next_addr
            op = kron(speye(T, 1 << (next_addr - curr_addr)), op)
            curr_addr = next_addr
        end

        op = kron(mat(next_block), op)
        curr_addr += nqubits(next_block)
    end

    if curr_addr <= N
        op = kron(speye(T, 1 << (N - curr_addr + 1)), op)
    end
    op
end
