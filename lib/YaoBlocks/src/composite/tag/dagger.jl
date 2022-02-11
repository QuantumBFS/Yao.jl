export Daggered

"""
    Daggered{BT, N, D} <: TagBlock{BT,N, D}

Wrapper block allowing to execute the inverse of a block of quantum circuit.
"""
struct Daggered{BT<:AbstractBlock,N,D} <: TagBlock{BT,N,D}
    content::BT
end

"""
    Daggered(x)

Create a [`Daggered`](@ref) block with given block `x`.

# Example

The inverse QFT is not hermitian, thus it will be tagged with a `Daggered` block.

```jldoctest; setup=:(using YaoBlocks)
julia> A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))));

julia> B(n, i) = chain(n, i==j ? put(i=>H) : A(j, i) for j in i:n);

julia> qft(n) = chain(B(n, i) for i in 1:n);

julia> struct QFT{N} <: PrimitiveBlock{N} end

julia> QFT(n) = QFT{n}();

julia> circuit(::QFT{N}) where N = qft(N);

julia> YaoBlocks.mat(x::QFT) = mat(circuit(x));

julia> QFT(2)'
 [†]QFT{2}
```
"""
Daggered(x::BT) where {N,D,BT<:AbstractBlock{N,D}} = Daggered{BT,N,D}(x)

PropertyTrait(::Daggered) = PreserveAll()
mat(::Type{T}, blk::Daggered) where {T} = adjoint(mat(T, content(blk)))
chsubblocks(blk::Daggered, target::AbstractBlock) = Daggered(target)

Base.adjoint(x::AbstractBlock) = ishermitian(x) ? x : Daggered(x)
Base.adjoint(x::Daggered) = content(x)
Base.copy(x::Daggered) = Daggered(copy(content(x)))
