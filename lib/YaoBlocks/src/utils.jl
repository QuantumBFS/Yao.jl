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

##################### Entry Table #########################
struct EntryTable{IT<:DitStr, ET}
    configs::Vector{IT}
    amplitudes::Vector{ET}
end
function YaoArrayRegister.print_table(io::IO, t::EntryTable; digits::Int=5)
    println(io, "$(typeof(t)):")
    for (i, a) in zip(t.configs, t.amplitudes)
        println(io, "  $i   $(round(a; digits))")
    end
end
Base.show(io::IO, ::MIME"text/plain", t::EntryTable) = YaoArrayRegister.print_table(io, t; digits=5)
Base.show(io::IO, t::EntryTable) = YaoArrayRegister.print_table(io, t; digits=5)
Base.:(==)(e1::EntryTable, e2::EntryTable) = e1.configs == e2.configs && e1.amplitudes == e2.amplitudes
Base.length(et::EntryTable) = length(et.configs)
Base.iterate(et::EntryTable, args...) = iterate(zip(et.configs, et.amplitudes), args...)

function Base.Vector(et::EntryTable{<:DitStr{D,N}, ET}) where {D,N,ET}
    v = zeros(ET, D^N)
    for (c, a) in et
        v[buffer(c)+1] += a  # accumulate to support duplicated entries
    end
    return v
end
function SparseArrays.SparseVector(et::EntryTable{DitStr{D,N,TI}, ET}) where {D,N,ET,TI}
    length(et.configs) == 0 && return SparseVector(D^N, TI[], ET[])
    locs = buffer.(et.configs) .+ 1
    locs, amps = _cleanup(locs, et.amplitudes; zero_threshold=0.0)
    return SparseVector(D^N, locs, amps)
end

"""
    cleanup(entries::EntryTable; zero_threshold=0.0)

Clean up the entry table by merging items and clean up zeros.
Any value with amplitude ≤ `zero_threshold` will be regarded as zero.
"""
function cleanup(et::EntryTable; zero_threshold=0.0)
    EntryTable(_cleanup(et.configs, et.amplitudes; zero_threshold)...)
end
function _cleanup(locs, amps; zero_threshold)
    length(locs) == 0 && return locs, amps
    order = sortperm(locs; by=Int)
    locs, amps = locs[order], amps[order]
    k = 1
    pre = locs[1]
    @inbounds for i=2:length(locs)
        this = locs[i]
        if this != pre
            if abs(amps[k]) > zero_threshold
                k += 1
            end
            locs[k] = this
            amps[k] = amps[i]
        else
            amps[k] += amps[i]
        end
        pre = this
    end
    if abs(amps[k]) <= zero_threshold
        k -= 1
    end
    if k != length(locs)
        resize!(locs, k)
        resize!(amps, k)
    end
    return locs, amps
end

function Base.merge(et::EntryTable{DitStr{D,N,TI},T}, ets::EntryTable{DitStr{D,N,TI},T}...) where {D,N,TI,T}
    EntryTable(vcat(et.configs, [e.configs for e in ets]...), vcat(et.amplitudes, [e.amplitudes for e in ets]...))
end

SparseArrays.sparse(et::EntryTable) = SparseVector(et)
Base.vec(et::EntryTable) = Vector(et)