using YaoBase
using TupleTools
export KronBlock, kron

const KronLocT = Union{Int,UnitRange{Int}}

"""
    KronBlock{N,D,M,MT<:NTuple{M,Any}} <: CompositeBlock{N,D}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{N,D,M,MT<:NTuple{M,Any}} <: CompositeBlock{N,D}
    locs::NTuple{M,UnitRange{Int}}
    blocks::MT

    function KronBlock{N,D,M,MT}(
        locs::NTuple{M,UnitRange{Int}},
        blocks::MT,
    ) where {N,D,M,MT<:NTuple{M,AbstractBlock{N0,D} where N0}}
        perm = TupleTools.sortperm(locs, by = first)
        locs = TupleTools.permute(locs, perm)
        blocks = TupleTools.permute(blocks, perm)
        @assert_locs_safe N locs

        for (each, b) in zip(locs, blocks)
            length(each) != nqudits(b) && throw(
                LocationConflictError("locs $locs is inconsistent with target block $b"),
            )
        end
        return new{N,D,M,typeof(blocks)}(locs, blocks)
    end
end

KronBlock{N}(::Tuple{}, ::Tuple{}; nlevel=2) where N = KronBlock{N,nlevel,0,Tuple{}}((), ())
KronBlock{N}(
    locs::NTuple{M,UnitRange{Int}},
    blocks::MT,
) where {N,D,M,MT<:NTuple{M,AbstractBlock{N0,D} where N0}} = KronBlock{N,D,M,MT}(locs, blocks)

function KronBlock{N}(itr::Pair{<:Any,<:AbstractBlock{M,D} where M}...) where {N,D}
    locs = map(itr) do p
        _render_kronloc(first(p))
    end
    return KronBlock{N}(locs, last.(itr))
end

function KronBlock(itr::AbstractBlock...)
    locs = UnitRange{Int}[]
    count = 0
    for each in itr
        count += nqudits(each)
        push!(locs, count-nqudits(each)+1:count)
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
nqudits: 4
kron
├─ 1=>X
└─ 3=>Y
```
"""
Base.kron(total::Int, blocks::Pair{<:Any,<:AbstractBlock}...) = KronBlock{total}(blocks...)
Base.kron(total::Int) = KronBlock{total}()

"""
    kron(blocks::AbstractBlock...)
    kron(n, itr)

Return a [`KronBlock`](@ref), with total number of qubits `n`, and `blocks` should use all
the locations on `n` wires in quantum circuits.

# Example

You can use kronecker product to composite small blocks to a large blocks.

```jldoctest; setup=:(using YaoBlocks)
julia> kron(X, Y, Z, Z)
nqudits: 4
kron
├─ 1=>X
├─ 2=>Y
├─ 3=>Z
└─ 4=>Z
```
"""
Base.kron(blocks::AbstractBlock...) = KronBlock(blocks...)
Base.kron(fs::Union{Function,AbstractBlock}...) = @λ(n -> kron(n, fs...))

function Base.kron(total::Int, blocks::AbstractBlock...)
    sum(nqudits, blocks) == total || error("total number of qubits mismatch")
    return kron(blocks...)
end

function _render_kronloc(l)
    for i = 1:length(l)-1
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
(n -> kron(n, ((n  ->  put(n, 1 => X)), (n  ->  put(n, 1 => X)))...))

julia> kron(X for _ in 1:2)
nqudits: 2
kron
├─ 1=>X
└─ 2=>X

julia> kron(1=>X, 3=>Y)
(n -> kron(n, (1 => X, 3 => Y)...))
```
"""
Base.kron(blocks::Pair{<:Any,<:AbstractBlock}...) = @λ(n -> kron(n, blocks...))
Base.kron(blocks::Base.Generator) = kron(blocks...)

occupied_locs(k::KronBlock) = (Iterators.flatten(k.locs)...,)
subblocks(x::KronBlock) = x.blocks
chsubblocks(pb::KronBlock{N}, it) where {N} = KronBlock{N}(pb.locs, (it...,))
cache_key(x::KronBlock) = [cache_key(each) for each in x.blocks]
color(::Type{T}) where {T<:KronBlock} = :cyan

function mat(::Type{T}, k::KronBlock{N,D,M}) where {T,N,D,M}
    M == 0 && return IMatrix{D^N,T}()
    ntrail = N - last(last(k.locs))  # number of trailing bits
    num_bit_list = map(i -> first(k.locs[i]) - (i > 1 ? last(k.locs[i-1]) : 0) - 1, 1:M)
    return reduce(
        Iterators.reverse(zip(subblocks(k), num_bit_list)),
        init = IMatrix{D^ntrail,T}(),
    ) do x, y
        kron(x, mat(T, y[1]), IMatrix(D^y[2]))
    end
end

function _apply!(r::AbstractRegister, k::KronBlock)
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
