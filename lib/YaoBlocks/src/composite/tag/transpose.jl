export Transposed

"""
    Transposed{BT, D} <: TagBlock{BT,D}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Transposed{BT<:AbstractBlock,D} <: TagBlock{BT,D}
    content::BT
end

"""
    Transposed(block)

Create a [`Transposed`](@ref) block.
Let ``G`` be a input block, `G'` or `Transposed(block)` in code represents ``G^\\dagger``.

### Examples

The inverse QFT is not hermitian, thus it will be tagged with a `Transposed` block.

```jldoctest; setup=:(using YaoBlocks)
julia> A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))));

julia> B(n, i) = chain(n, i==j ? put(i=>H) : A(j, i) for j in i:n);

julia> qft(n) = chain(B(n, i) for i in 1:n);

julia> struct QFT <: PrimitiveBlock{2} n::Int end

julia> YaoBlocks.nqudits(q::QFT) = q.n


julia> circuit(q::QFT) = qft(nqubits(q));

julia> YaoBlocks.mat(x::QFT) = mat(circuit(x));

julia> QFT(2)'
 [†]QFT
```
"""
Transposed(x::BT) where {D,BT<:AbstractBlock{D}} = Transposed{BT,D}(x)

PropertyTrait(::Transposed) = PreserveAll()
mat(::Type{T}, blk::Transposed) where {T} = transpose(mat(T, content(blk)))
chsubblocks(blk::Transposed, target::AbstractBlock) = Transposed(target)

Base.transpose(x::AbstractBlock) = ishermitian(x) ? x : Transposed(x)
Base.transpose(x::Transposed) = content(x)
Base.copy(x::Transposed) = Transposed(copy(content(x)))

function unsafe_getindex(::Type{T}, d::Transposed, i::Integer, j::Integer) where {T}
    return unsafe_getindex(T, content(d), j, i) |> conj
end
function unsafe_getcol(::Type{T}, d::Transposed, j::DitStr{D}) where {T,D}
    locs, vals = force_getrowconj(T, content(d), j)
    return locs, vals
end
