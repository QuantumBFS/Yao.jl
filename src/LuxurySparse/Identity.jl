"""
    Identity{N, Tv}()
    Identity{N}() where N = Identity{N, Int64}()
    Identity(A::AbstractMatrix{T}) where T -> Identity

Identity matrix, with size N as label, use `Int64` as its default type, both `*` and `kron` are optimized.
"""
struct Identity{N, Tv} <: AbstractMatrix{Tv} end
Identity{N}() where N = Identity{N, Bool}()

size(A::Identity{N}, i::Int) where N = N
size(A::Identity{N}) where N = (N, N)
getindex(A::Identity{N, T}, i::Integer, j::Integer) where {N, T} = T(i==j)

####### sparse matrix ######
nnz(M::Identity{N}) where N = N
nonzeros(M::Identity{N, T}) where {N, T} = ones(T, N)
ishermitian(D::Identity) = true

similar(::Identity{N, Tv}) where {N, Tv} = Identity{N, Tv}()
copyto!(A::Identity{N}, B::Identity{N}) where N = A

"""
    I([type], n) -> Identity

Returns identity matrix.
"""
function I end

I(n::Int) = Identity{n, Bool}()
I(::Type{T}, n::Int) where T = Identity{n, T}()
I(A::AbstractMatrix) = Identity(A)
