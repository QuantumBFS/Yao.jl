export GeneralMatrixBlock, matblock

"""
    GeneralMatrixBlock{D, MT} <: PrimitiveBlock{D}
    GeneralMatrixBlock{D}(m, n, A, tag="matblock(...)")
    GeneralMatrixBlock(A; nlevel=2, tag="matblock(...)")

General matrix gate wraps a matrix operator to quantum gates. This is the most
general form of a quantum gate.

### Arguments

* `m` and `n` are the number of dits in row and column.
* `A` is a matrix.
* `tag` is the printed information.
* `D` and `nlevel` are the number of levels in each qudit.
"""
struct GeneralMatrixBlock{D,T,MT<:AbstractMatrix{T}} <: PrimitiveBlock{D}
    m::Int
    n::Int
    mat::MT
    tag::String

    function GeneralMatrixBlock{D}(m::Int, n::Int, A::MT, tag::String="matblock(...)") where {D,T,MT<:AbstractMatrix{T}}
        (D^m, D^n) == size(A) ||
            throw(DimensionMismatch("expect a $(D^m) x $(D^n) matrix, got $(size(A))"))

        return new{D,T,MT}(m, n, A, tag)
    end
end
YaoAPI.nqudits(m::GeneralMatrixBlock) = m.n

GeneralMatrixBlock(m::AbstractMatrix; nlevel=2, tag="matblock(...)") = GeneralMatrixBlock{nlevel}(logdi.(size(m), nlevel)..., m, tag)

"""
    matblock(mat_or_block; nlevel=2, tag="matblock(...)")

Create a [`GeneralMatrixBlock`](@ref) with a matrix `m`.

### Examples

```jldoctest; setup=:(using YaoBlocks)
julia> matblock(ComplexF64[0 1;1 0])
matblock(...)
```

!!!warn
    
    Instead of converting it to the default data type `ComplexF64`,
    this will return its contained matrix when calling `mat`.
"""
matblock(m::AbstractMatrix; nlevel=2, tag="matblock(...)") = GeneralMatrixBlock(m; nlevel, tag)
matblock(m::AbstractBlock{D}; tag="matblock(...)") where {D} = GeneralMatrixBlock(mat(m); nlevel=D, tag)

cache_key(m::GeneralMatrixBlock) = hash(m.mat)

"""
    mat(A::GeneralMatrixBlock)

Return the matrix of general matrix block.

!!! warn
    
    Instead of converting it to the default data type `ComplexF64`,
    this will return its contained matrix.
"""
mat(A::GeneralMatrixBlock) = A.mat

function mat(::Type{T}, A::GeneralMatrixBlock) where {T}
    if eltype(A.mat) == T
        return A.mat
    else
        # this errors before, but since we allow one to specify T in mat
        # this should be allowed but with a suggestion
        @warn "converting $(eltype(A.mat)) to eltype $T, consider create another matblock with eltype $T"
        return copyto!(similar(A.mat, T), A.mat)
    end
end

Base.:(==)(A::GeneralMatrixBlock, B::GeneralMatrixBlock) = A.mat == B.mat
Base.copy(A::GeneralMatrixBlock) = GeneralMatrixBlock(copy(A.mat))
Base.adjoint(x::GeneralMatrixBlock) = Daggered(x)
function isdiagonal(op::GeneralMatrixBlock)
    op.mat isa Diagonal || op.mat isa IMatrix
end
Base.setindex!(A::GeneralMatrixBlock, val, args::DitStr...) = setindex!(A.mat, val, (buffer.(args) .+ 1)...)