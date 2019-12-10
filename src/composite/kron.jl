using YaoBase
using TupleTools
export KronBlock, kron

const KronLocT = Union{Int,UnitRange{Int}}

"""
    KronBlock{N, T, MT<:AbstractBlock} <: CompositeBlock{N, T}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N,M,MT<:NTuple{M,Any}} <: CompositeBlock{N}
    locs::NTuple{M,UnitRange{Int}}
    blocks::MT

    function KronBlock{N,M,MT}(
        locs::NTuple{M,UnitRange{Int}},
        blocks::MT,
    ) where {N,M,MT<:NTuple{M,AbstractBlock}}
        perm = TupleTools.sortperm(locs, by = first)
        locs = TupleTools.permute(locs, perm)
        blocks = TupleTools.permute(blocks, perm)
        @assert_locs_safe N locs

        for (each, b) in zip(locs, blocks)
            length(each) != nqubits(b) &&
            throw(LocationConflictError("locs $locs is inconsistent with target block $b"))
        end
        return new{N,M,typeof(blocks)}(locs, blocks)
    end
end

KronBlock{N}(locs::NTuple{M,UnitRange{Int}}, blocks::MT) where {N,M,MT<:NTuple{M,AbstractBlock}} =
    KronBlock{N,M,MT}(locs, blocks)

function KronBlock{N}(itr::Pair{<:Any,<:AbstractBlock}...) where {N}
    locs = map(itr) do p
        _render_kronloc(first(p))
    end
    return KronBlock{N}(locs, last.(itr))
end

function KronBlock(itr::AbstractBlock...)
    locs = UnitRange{Int}[]
    count = 0
    for each in itr
        count += nqubits(each)
        push!(locs, count-nqubits(each)+1:count)
    end
    return KronBlock{count}((locs...,), itr)
end

KronBlock(blk::KronBlock) = copy(blk)

"""
    kron(n, blocks::Pair{<:Any, <:AbstractBlock}...)

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
Base.kron(total::Int, blocks::Pair{<:Any,<:AbstractBlock}...) = KronBlock{total}(blocks...)

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

function _render_kronloc(l)
    for i in 1:length(l)-1
        l[i+1] == l[i] + 1 || error("Non-Contiguous location in Kron!")
    end
    l[1]:l[end]
end

Base.kron(total::Int, blocks::Base.Generator) = kron(total, blocks...)
function Base.kron(total::Int, blocks::Union{Pair{<:Any,<:AbstractBlock},AbstractBlock}...)
    throw(MethodError(:kron, blocks))
end

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
Base.kron(blocks::Pair{<:Any,<:AbstractBlock}...) = @λ(n -> kron(n, blocks...))
Base.kron(blocks::Base.Generator) = kron(blocks...)

occupied_locs(k::KronBlock) = (Iterators.flatten(k.locs)...,)
subblocks(x::KronBlock) = x.blocks
chsubblocks(pb::KronBlock{N}, it) where {N} = KronBlock{N}(pb.locs, (it...,))
cache_key(x::KronBlock) = [cache_key(each) for each in x.blocks]
color(::Type{T}) where {T<:KronBlock} = :cyan

function mat(::Type{T}, k::KronBlock{N,M}) where {T,N,M}
    ntrail = N - last(last(k.locs))  # number of trailing bits
    num_bit_list = map(i -> first(k.locs[i]) - (i > 1 ? last(k.locs[i-1]) : 0) - 1, 1:M)
    return reduce(
        Iterators.reverse(zip(subblocks(k), num_bit_list)),
        init = IMatrix{1 << ntrail,T}(),
    ) do x, y
        kron(x, mat(T, y[1]), IMatrix(1 << y[2]))
    end
end

function apply!(r::AbstractRegister, k::KronBlock)
    _check_size(r, k)
    for (locs, block) in zip(k.locs, k.blocks)
        _instruct!(r, block, Tuple(locs))
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
    locs = copy.(k.locs)
    blocks = copy.(k.blocks)
    return KronBlock{N}(locs, blocks)
end

function Base.getindex(k::KronBlock, addr::UnitRange)
    index = findfirst(==(addr), k.locs)
    return k.blocks[index]
end
Base.getindex(k::KronBlock, addr::Integer) = getindex(k, addr:addr)

function Base.iterate(k::KronBlock, st = 1)
    if st > length(k)
        return nothing
    else
        return (k.locs[st], k.blocks[st]), st + 1
    end
end

Base.eltype(k::KronBlock) = Tuple{UnitRange{Int},AbstractBlock}
Base.length(k::KronBlock) = length(k.blocks)
Base.eachindex(k::KronBlock) = k.locs

function Base.:(==)(lhs::KronBlock{N}, rhs::KronBlock{N}) where {N}
    return all(lhs.locs .== rhs.locs) && all(lhs.blocks .== rhs.blocks)
end

Base.adjoint(blk::KronBlock{N}) where {N} = KronBlock{N}(blk.locs, map(adjoint, blk.blocks))

YaoBase.ishermitian(k::KronBlock) = all(ishermitian, k.blocks) || ishermitian(mat(k))
YaoBase.isunitary(k::KronBlock) = all(isunitary, k.blocks) || isunitary(mat(k))
YaoBase.isreflexive(k::KronBlock) = all(isreflexive, k.blocks) || isreflexive(mat(k))
