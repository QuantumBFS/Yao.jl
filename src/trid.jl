## (complex) symmetric tridiagonal matrices
struct SymTridiagonal{T,V<:AbstractVector{T}} <: AbstractMatrix{T}
    dv::V                        # diagonal
    ev::V                        # subdiagonal
    function SymTridiagonal{T}(dv::V, ev::V) where {T,V<:AbstractVector{T}}
        if !(length(dv) - 1 <= length(ev) <= length(dv))
            throw(DimensionMismatch("subdiagonal has wrong length. Has length $(length(ev)), but should be either $(length(dv) - 1) or $(length(dv))."))
        end
        new{T,V}(dv,ev)
    end
end

SymTridiagonal(dv::V, ev::V) where {T,V<:AbstractVector{T}} = SymTridiagonal{T}(dv, ev)

function SymTridiagonal(A::AbstractMatrix)
    if diag(A,1) == diag(A,-1)
        SymTridiagonal(diag(A,0), diag(A,1))
    else
        throw(ArgumentError("matrix is not symmetric; cannot convert to SymTridiagonal"))
    end
end

SymTridiagonal{T}(S::SymTridiagonal) where {T} =
    SymTridiagonal(convert(AbstractVector{T}, S.dv), convert(AbstractVector{T}, S.ev))
AbstractMatrix{T}(S::SymTridiagonal) where {T} =
    SymTridiagonal(convert(AbstractVector{T}, S.dv), convert(AbstractVector{T}, S.ev))
function Matrix{T}(M::SymTridiagonal) where T
    n = size(M, 1)
    Mf = zeros(T, n, n)
    @inbounds begin
        @simd for i = 1:n-1
            Mf[i,i] = M.dv[i]
            Mf[i+1,i] = M.ev[i]
            Mf[i,i+1] = M.ev[i]
        end
        Mf[n,n] = M.dv[n]
    end
    return Mf
end
Matrix(M::SymTridiagonal{T}) where {T} = Matrix{T}(M)
Array(M::SymTridiagonal) = Matrix(M)

size(A::SymTridiagonal) = (length(A.dv), length(A.dv))
function size(A::SymTridiagonal, d::Integer)
    if d < 1
        throw(ArgumentError("dimension must be ≥ 1, got $d"))
    elseif d<=2
        return length(A.dv)
    else
        return 1
    end
end

# For S<:SymTridiagonal, similar(S[, neweltype]) should yield a SymTridiagonal matrix.
# On the other hand, similar(S, [neweltype,] shape...) should yield a sparse matrix.
# The first method below effects the former, and the second the latter.
similar(S::SymTridiagonal, ::Type{T}) where {T} = SymTridiagonal(similar(S.dv, T), similar(S.ev, T))
# The method below is moved to SparseArrays for now
# similar(S::SymTridiagonal, ::Type{T}, dims::Union{Dims{1},Dims{2}}) where {T} = spzeros(T, dims...)

#Elementary operations
for func in (:conj, :copy, :real, :imag)
    @eval ($func)(M::SymTridiagonal) = SymTridiagonal(($func)(M.dv), ($func)(M.ev))
end

transpose(S::SymTridiagonal) = S
adjoint(S::SymTridiagonal{<:Real}) = S
adjoint(S::SymTridiagonal) = Adjoint(S)
Base.copy(S::Adjoint{<:Any,<:SymTridiagonal}) = SymTridiagonal(map(x -> copy.(adjoint.(x)), (S.parent.dv, S.parent.ev))...)
Base.copy(S::Transpose{<:Any,<:SymTridiagonal}) = SymTridiagonal(map(x -> copy.(transpose.(x)), (S.parent.dv, S.parent.ev))...)

function diag(M::SymTridiagonal, n::Integer=0)
    # every branch call similar(..., ::Int) to make sure the
    # same vector type is returned independent of n
    absn = abs(n)
    if absn == 0
        return copyto!(similar(M.dv, length(M.dv)), M.dv)
    elseif absn==1
        return copyto!(similar(M.ev, length(M.ev)), M.ev)
    elseif absn <= size(M,1)
        return fill!(similar(M.dv, size(M,1)-absn), 0)
    else
        throw(ArgumentError(string("requested diagonal, $n, must be at least $(-size(M, 1)) ",
            "and at most $(size(M, 2)) for an $(size(M, 1))-by-$(size(M, 2)) matrix")))
    end
end

+(A::SymTridiagonal, B::SymTridiagonal) = SymTridiagonal(A.dv+B.dv, A.ev+B.ev)
-(A::SymTridiagonal, B::SymTridiagonal) = SymTridiagonal(A.dv-B.dv, A.ev-B.ev)
*(A::SymTridiagonal, B::Number) = SymTridiagonal(A.dv*B, A.ev*B)
*(B::Number, A::SymTridiagonal) = A*B
/(A::SymTridiagonal, B::Number) = SymTridiagonal(A.dv/B, A.ev/B)
==(A::SymTridiagonal, B::SymTridiagonal) = (A.dv==B.dv) && (A.ev==B.ev)

function mul!(C::StridedVecOrMat, S::SymTridiagonal, B::StridedVecOrMat)
    m, n = size(B, 1), size(B, 2)
    if !(m == size(S, 1) == size(C, 1))
        throw(DimensionMismatch("A has first dimension $(size(S,1)), B has $(size(B,1)), C has $(size(C,1)) but all must match"))
    end
    if n != size(C, 2)
        throw(DimensionMismatch("second dimension of B, $n, doesn't match second dimension of C, $(size(C,2))"))
    end

    α = S.dv
    β = S.ev
    @inbounds begin
        for j = 1:n
            x₀, x₊ = B[1, j], B[2, j]
            β₀ = β[1]
            C[1, j] = α[1]*x₀ + x₊*β₀
            for i = 2:m - 1
                x₋, x₀, x₊ = x₀, x₊, B[i + 1, j]
                β₋, β₀ = β₀, β[i]
                C[i, j] = β₋*x₋ + α[i]*x₀ + β₀*x₊
            end
            C[m, j] = β₀*x₀ + α[m]*x₊
        end
    end

    return C
end

(\)(T::SymTridiagonal, B::StridedVecOrMat) = ldltfact(T)\B

eigfact!(A::SymTridiagonal{<:BlasReal}) = Eigen(LAPACK.stegr!('V', A.dv, A.ev)...)
eigfact(A::SymTridiagonal{T}) where T = eigfact!(copy_oftype(A, eigtype(T)))

eigfact!(A::SymTridiagonal{<:BlasReal}, irange::UnitRange) =
    Eigen(LAPACK.stegr!('V', 'I', A.dv, A.ev, 0.0, 0.0, irange.start, irange.stop)...)
eigfact(A::SymTridiagonal{T}, irange::UnitRange) where T =
    eigfact!(copy_oftype(A, eigtype(T)), irange)

eigfact!(A::SymTridiagonal{<:BlasReal}, vl::Real, vu::Real) =
    Eigen(LAPACK.stegr!('V', 'V', A.dv, A.ev, vl, vu, 0, 0)...)
eigfact(A::SymTridiagonal{T}, vl::Real, vu::Real) where T =
    eigfact!(copy_oftype(A, eigtype(T)), vl, vu)

eigvals!(A::SymTridiagonal{<:BlasReal}) = LAPACK.stev!('N', A.dv, A.ev)[1]
eigvals(A::SymTridiagonal{T}) where T = eigvals!(copy_oftype(A, eigtype(T)))

eigvals!(A::SymTridiagonal{<:BlasReal}, irange::UnitRange) =
    LAPACK.stegr!('N', 'I', A.dv, A.ev, 0.0, 0.0, irange.start, irange.stop)[1]
eigvals(A::SymTridiagonal{T}, irange::UnitRange) where T =
    eigvals!(copy_oftype(A, eigtype(T)), irange)

eigvals!(A::SymTridiagonal{<:BlasReal}, vl::Real, vu::Real) =
    LAPACK.stegr!('N', 'V', A.dv, A.ev, vl, vu, 0, 0)[1]
eigvals(A::SymTridiagonal{T}, vl::Real, vu::Real) where T =
    eigvals!(copy_oftype(A, eigtype(T)), vl, vu)

#Computes largest and smallest eigenvalue
eigmax(A::SymTridiagonal) = eigvals(A, size(A, 1):size(A, 1))[1]
eigmin(A::SymTridiagonal) = eigvals(A, 1:1)[1]

#Compute selected eigenvectors only corresponding to particular eigenvalues
eigvecs(A::SymTridiagonal) = eigfact(A).vectors

"""
    eigvecs(A::SymTridiagonal[, eigvals]) -> Matrix

Return a matrix `M` whose columns are the eigenvectors of `A`. (The `k`th eigenvector can
be obtained from the slice `M[:, k]`.)

If the optional vector of eigenvalues `eigvals` is specified, `eigvecs`
returns the specific corresponding eigenvectors.

# Examples
```jldoctest
julia> A = SymTridiagonal([1.; 2.; 1.], [2.; 3.])
3×3 SymTridiagonal{Float64,Array{Float64,1}}:
 1.0  2.0   ⋅
 2.0  2.0  3.0
  ⋅   3.0  1.0

julia> eigvals(A)
3-element Array{Float64,1}:
 -2.1400549446402604
  1.0000000000000002
  5.140054944640259

julia> eigvecs(A)
3×3 Array{Float64,2}:
  0.418304  -0.83205      0.364299
 -0.656749  -7.39009e-16  0.754109
  0.627457   0.5547       0.546448

julia> eigvecs(A, [1.])
3×1 Array{Float64,2}:
  0.8320502943378438
  4.263514128092366e-17
 -0.5547001962252291
```
"""
eigvecs(A::SymTridiagonal{<:BlasFloat}, eigvals::Vector{<:Real}) = LAPACK.stein!(A.dv, A.ev, eigvals)

###################
# Generic methods #
###################

## structured matrix methods ##
function Base.replace_in_print_matrix(A::SymTridiagonal, i::Integer, j::Integer, s::AbstractString)
    i==j-1||i==j||i==j+1 ? s : Base.replace_with_centered_mark(s)
end

#Implements the inverse using the recurrence relation between principal minors
# a, b, c are assumed to be the subdiagonal, diagonal, and superdiagonal of
# a tridiagonal matrix.
#Reference:
#    R. Usmani, "Inversion of a tridiagonal Jacobi matrix",
#    Linear Algebra and its Applications 212-213 (1994), pp.413-414
#    doi:10.1016/0024-3795(94)90414-6
function inv_usmani(a::V, b::V, c::V) where {T,V<:AbstractVector{T}}
    n = length(b)
    θ = zeros(T, n+1) #principal minors of A
    θ[1] = 1
    n>=1 && (θ[2] = b[1])
    for i=2:n
        θ[i+1] = b[i]*θ[i]-a[i-1]*c[i-1]*θ[i-1]
    end
    φ = zeros(T, n+1)
    φ[n+1] = 1
    n>=1 && (φ[n] = b[n])
    for i=n-1:-1:1
        φ[i] = b[i]*φ[i+1]-a[i]*c[i]*φ[i+2]
    end
    α = Matrix{T}(undef, n, n)
    for i=1:n, j=1:n
        sign = (i+j)%2==0 ? (+) : (-)
        if i<j
            α[i,j]=(sign)(prod(c[i:j-1]))*θ[i]*φ[j+1]/θ[n+1]
        elseif i==j
            α[i,i]=                       θ[i]*φ[i+1]/θ[n+1]
        else #i>j
            α[i,j]=(sign)(prod(a[j:i-1]))*θ[j]*φ[i+1]/θ[n+1]
        end
    end
    α
end

#Implements the determinant using principal minors
#Inputs and reference are as above for inv_usmani()
function det_usmani(a::V, b::V, c::V) where {T,V<:AbstractVector{T}}
    n = length(b)
    θa = one(T)
    if n == 0
        return θa
    end
    θb = b[1]
    for i=2:n
        θb, θa = b[i]*θb-a[i-1]*c[i-1]*θa, θb
    end
    return θb
end

inv(A::SymTridiagonal) = inv_usmani(A.ev, A.dv, A.ev)
det(A::SymTridiagonal) = det_usmani(A.ev, A.dv, A.ev)

function getindex(A::SymTridiagonal{T}, i::Integer, j::Integer) where T
    if !(1 <= i <= size(A,2) && 1 <= j <= size(A,2))
        throw(BoundsError(A, (i,j)))
    end
    if i == j
        return A.dv[i]
    elseif i == j + 1
        return A.ev[j]
    elseif i + 1 == j
        return A.ev[i]
    else
        return zero(T)
    end
end

function setindex!(A::SymTridiagonal, x, i::Integer, j::Integer)
    @boundscheck checkbounds(A, i, j)
    if i == j
        @inbounds A.dv[i] = x
    else
        throw(ArgumentError("cannot set off-diagonal entry ($i, $j)"))
    end
    return x
end
