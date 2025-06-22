export KronBlock, kron

const KronLocT = Union{Int,UnitRange{Int}}

"""
    KronBlock{D,M,MT<:NTuple{M,Any}} <: CompositeBlock{D}

composite block that combine blocks by kronecker product.
"""
struct KronBlock{D,M,MT<:NTuple{M,Any}} <: CompositeBlock{D}
    n::Int
    locs::NTuple{M,UnitRange{Int}}
    blocks::MT

    function KronBlock{D,M,MT}(n::Int,
        locs::NTuple{M,UnitRange{Int}},
        blocks::MT,
    ) where {D,M,MT<:NTuple{M,AbstractBlock{D}}}
        perm = TupleTools.sortperm(locs, by = first)
        locs = TupleTools.permute(locs, perm)
        blocks = TupleTools.permute(blocks, perm)
        @assert_locs_safe n locs

        for (each, b) in zip(locs, blocks)
            length(each) != nqudits(b) && throw(
                LocationConflictError("locs $locs is inconsistent with target block $b"),
            )
        end
        return new{D,M,typeof(blocks)}(n, locs, blocks)
    end
end

KronBlock(n::Int, ::Tuple{}, ::Tuple{}; nlevel=2) = KronBlock{nlevel,0,Tuple{}}(n, (), ())
KronBlock(n::Int,
    locs::NTuple{M,UnitRange{Int}},
    blocks::MT,
) where {D,M,MT<:NTuple{M,AbstractBlock{D}}} = KronBlock{D,M,MT}(n,locs, blocks)

function KronBlock(n::Int, itr::Pair{<:Any,<:AbstractBlock{D}}...) where {D}
    locs = map(itr) do p
        _render_kronloc(first(p))
    end
    return KronBlock(n, locs, last.(itr))
end

function KronBlock(itr::AbstractBlock...)
    locs = UnitRange{Int}[]
    count = 0
    for each in itr
        count += nqudits(each)
        push!(locs, count-nqudits(each)+1:count)
    end
    return KronBlock(count, (locs...,), itr)
end

KronBlock(blk::KronBlock) = copy(blk)

nqudits(pb::KronBlock) = pb.n

"""
    kron(n, locs_and_blocks::Pair{<:Any, <:AbstractBlock}...) -> KronBlock

Returns a `n`-qudit [`KronBlock`](@ref). The inputs contains a list of location-block pairs, where a location can be an integer or a range.
It is conceptually a [`chain`](@ref) of [`put`](@ref) block without address conflicts,
but it has a richer type information that can be useful for various purposes such as more efficient [`mat`](@ref) function.

Let ``I`` be a ``2\\times 2`` identity matrix, ``G`` and ``H`` be two ``2\\times 2`` matrix,
the matrix representation of `kron(n, i=>G, j=>H)` (assume ``j > i``) is defined as

```math
I^{\\otimes n-j} \\otimes H \\otimes I^{\\otimes j-i-1} \\otimes G \\otimes I^{i-1}
```

For multiple locations, the expression can be complicated.

### Examples

Use `kron` to construct a `KronBlock`, it will put an `X` gate on the `1`st qubit,
and a `Y` gate on the `3`rd qubit.

```jldoctest; setup=:(using Yao)
julia> kron(4, 1=>X, 3=>Y)
nqubits: 4
kron
├─ 1=>X
└─ 3=>Y
```
"""
Base.kron(total::Int, blocks::Pair{<:Any,<:AbstractBlock}...) = KronBlock(total, blocks...)
Base.kron(total::Int) = KronBlock(total)

"""
    kron(blocks::AbstractBlock...)
    kron(n, itr)

Return a [`KronBlock`](@ref), with total number of qubits `n`, and `blocks` should use all
the locations on `n` wires in quantum circuits.

### Examples

You can use kronecker product to composite small blocks to a large blocks.

```jldoctest; setup=:(using Yao)
julia> kron(X, Y, Z, Z)
nqubits: 4
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

### Examples

If you don't know the number of qubit yet, or you are just too lazy, it is fine.

```jldoctest; setup=:(using Yao)
julia> kron(put(1=>X) for _ in 1:2)
(n -> kron(n, ((n  ->  put(n, 1 => X)), (n  ->  put(n, 1 => X)))...))

julia> kron(X for _ in 1:2)
nqubits: 2
kron
├─ 1=>X
└─ 2=>X

julia> kron(1=>X, 3=>Y)
(n -> kron(n, (1 => X, 3 => Y)...))
```
"""
Base.kron(blocks::Pair{<:Any,<:AbstractBlock}...) = @λ(n -> kron(n, blocks...))
Base.kron(blocks::Base.Generator) = kron(blocks...)

occupied_locs(k::KronBlock) = (vcat([[getindex.(Ref(loc), occupied_locs(b))...] for (loc, b) in zip(k.locs, k.blocks)]...)...,)
subblocks(x::KronBlock) = x.blocks
chsubblocks(pb::KronBlock, it) = KronBlock(pb.n, pb.locs, (it...,))
chsubblocks(x::KronBlock, it::AbstractBlock) = chsubblocks(x, (it,))
cache_key(x::KronBlock) = [cache_key(each) for each in x.blocks]
color(::Type{T}) where {T<:KronBlock} = :cyan

function mat(::Type{T}, k::KronBlock{D,M}) where {T,D,M}
    M == 0 && return IMatrix{T}(D^k.n)
    ntrail = k.n - last(last(k.locs))  # number of trailing bits
    num_bit_list = map(i -> first(k.locs[i]) - (i > 1 ? last(k.locs[i-1]) : 0) - 1, 1:M)
    return reduce(
        Iterators.reverse(zip(subblocks(k), num_bit_list)),
        init = IMatrix{T}(D^ntrail),
    ) do x, y
        kron(x, mat(T, y[1]), IMatrix(D^y[2]))
    end
end

function YaoAPI.unsafe_apply!(r::AbstractRegister, k::KronBlock)
    for (locs, block) in zip(k.locs, k.blocks)
        _instruct!(r, block, Tuple(locs))
    end
    return r
end

function _instruct!(reg::AbstractRegister, block::AbstractBlock, locs)
    isnoisy(block) && return noisy_instruct!(reg, block, locs)
    instruct!(reg, mat_matchreg(reg, block), locs)
end
function noisy_instruct!(reg::AbstractRegister, k::KronBlock, locs)
    for (loc, block) in zip(k.locs, k.blocks)
        if isnoisy(block)
            noisy_instruct!(reg, block, Tuple(map(i -> locs[i], loc)))
        else
            instruct!(reg, mat_matchreg(reg, block), Tuple(map(i -> locs[i], loc)))
        end
    end
    return reg
end

# specialization
for G in [:X, :Y, :Z, :T, :S, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))
    @eval _instruct!(reg::AbstractRegister, block::$GT, locs) =
        instruct!(reg, Val($(QuoteNode(G))), locs)
end

function Base.copy(k::KronBlock)
    locs = copy.(k.locs)
    blocks = copy.(k.blocks)
    return KronBlock(k.n, locs, blocks)
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

function Base.:(==)(lhs::KronBlock, rhs::KronBlock)
    return nqudits(lhs) == nqudits(rhs) && length(lhs.locs) == length(rhs.locs) && all(lhs.locs .== rhs.locs) && all(lhs.blocks .== rhs.blocks)
end

Base.adjoint(blk::KronBlock) = KronBlock(blk.n, blk.locs, map(adjoint, blk.blocks))

LinearAlgebra.ishermitian(k::KronBlock) = all(ishermitian, k.blocks) || ishermitian(mat(k))
YaoAPI.isunitary(k::KronBlock) = all(isunitary, k.blocks) || isunitary(mat(k))
YaoAPI.isreflexive(k::KronBlock) = all(isreflexive, k.blocks) || isreflexive(mat(k))

function unsafe_getindex(::Type{T}, k::KronBlock{D}, i::Integer, j::Integer) where {T,D}
    kron_instruct_get_element(T, Val{D}(), nqudits(k), k.blocks, k.locs, i, j)
end
function unsafe_getcol(::Type{T}, pb::KronBlock{D}, j::DitStr{D}) where {T,D}
    kron_instruct_get_column(T, pb.blocks, pb.locs, j)
end
