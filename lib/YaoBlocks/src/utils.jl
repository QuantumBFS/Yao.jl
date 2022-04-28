export projector, print_blocktree

"""
    projector(x)

Return projector on `0` or projector on `1`.
"""
projector(x) = x == 0 ? mat(ConstGate.P0) : mat(ConstGate.P1)

"""
    print_subtypetree(::Type[, level=1, indent=4])

Print subtype tree, `level` specify the depth of the tree.
"""
function print_subtypetree(t::Type, level = 1, indent = 4)
    level == 1 && println(t)
    for s in subtypes(t)
        println(join(fill(" ", level * indent)) * string(s))
        print_subtypetree(s, level + 1, indent)
    end
end

"""
    rmlines(ex)

Remove `LineNumberNode` from an `Expr`.
"""
rmlines(ex::Expr) = begin
    hd = ex.head
    hd == :macrocall && return ex
    tl = map(rmlines, filter(!islinenumbernode, ex.args))
    Expr(hd, tl...)
end
rmlines(@nospecialize(a)) = a
islinenumbernode(@nospecialize(x)) = x isa LineNumberNode

"""
    rand_unitary([T=ComplexF64], N::Int) -> Matrix

Create a random unitary matrix.

### Examples

```jldoctest; setup=:(using Yao)
julia> isunitary(rand_unitary(2))
true

julia> eltype(rand_unitary(ComplexF32, 2))
ComplexF32 (alias for Complex{Float32})
```
"""
rand_unitary(N::Int) = rand_unitary(ComplexF64, N)
rand_unitary(::Type{T}, N::Int) where {T} = qr(randn(T, N, N)).Q |> Matrix

"""
    sprand_unitary([T=ComplexF64], N::Int, density) -> SparseMatrixCSC

Create a random sparse unitary matrix.
"""
sprand_unitary(N::Int, density::Real) = sprand_unitary(ComplexF64, N, density)
sprand_unitary(::Type{T}, N::Int, density::Real) where {T} =
    SparseMatrixCSC(qr(sprandn(T, N, N, density)).Q)


"""
    rand_hermitian([T=ComplexF64], N::Int) -> Matrix

Create a random hermitian matrix.

```jldoctest; setup=:(using Yao)
julia> ishermitian(rand_hermitian(2))
true
```
"""
rand_hermitian(N::Int) = rand_hermitian(ComplexF64, N)

function rand_hermitian(::Type{T}, N::Int) where {T}
    A = randn(T, N, N)
    A + A'
end

"""
    sprand_hermitian([T=ComplexF64], N, density)

Create a sparse random hermitian matrix.
"""
sprand_hermitian(N::Int, density) = sprand_hermitian(ComplexF64, N, density)

function sprand_hermitian(::Type{T}, N::Int, density::Real) where {T}
    A = sprandn(T, N, N, density)
    return A + A'
end

@static if VERSION < v"1.1.0"
    function SparseArrays.sprandn(::Type{T}, n::Int, m::Int, density::Real) where {T<:Real}
        return T.(sprandn(n, m, density))
    end

    function SparseArrays.sprandn(
        ::Type{Complex{T}},
        n::Int,
        m::Int,
        density::Real,
    ) where {T<:Real}
        return T.(sprandn(n, m, density)) + im * T.(sprandn(n, m, density))
    end
end

BitBasis.unsafe_reorder(A::IMatrix, orders::NTuple{N,<:Integer}; nlevel=2) where {N} = A

function BitBasis.unsafe_reorder(A::PermMatrix, orders::NTuple{N,<:Integer}; nlevel=2) where {N}
    od = Vector{Int}(undef, nlevel ^ length(orders))
    for (i, b) in enumerate(ReorderedBasis(orders))
        @inbounds od[i] = 1 + b
    end

    perm = similar(A.perm)
    vals = similar(A.vals)

    @simd for i = 1:length(perm)
        @inbounds perm[od[i]] = od[A.perm[i]]
        @inbounds vals[od[i]] = A.vals[i]
    end

    return PermMatrix(perm, vals)
end

function logdi(x::Integer, d::Integer)
    @assert x > 0 && d > 0
    res = log(x) / log(d)
    r = round(Int, res)
    if !(res ≈ r)
        throw(ArgumentError("`$x` is not an integer power of `$d`."))
    end
    return r
end
