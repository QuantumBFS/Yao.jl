export batch_normalize,
    batch_normalize!,
    rotmat,
    rand_hermitian,
    rand_unitary,
    sprand_hermitian,
    sprand_unitary,
    general_controlled_gates,
    general_c1_gates,
    linop2dense,
    # kron
    hilbertkron,
    batched_kron!,
    batched_kron,
    kron!,
    # norms
    trnorm,
    nucnorm,
    # fidelity
    pure_state_fidelity,
    density_fidelity,
    purification_fidelity,
    # matrix tools
    autostatic

using LuxurySparse, LinearAlgebra, BitBasis
import LinearAlgebra: svdvals

"""
nucnorm(m)

Computes the nuclear norm of a matrix `m`.
"""
function nucnorm(m::AbstractMatrix)
    norm(svdvals(m),1)
end

"""
trnorm(m)

Computes the trace norm of a matrix `m`.
"""
trnorm(m::AbstractMatrix) = nucnorm(m)


"""
    batch_normalize!(matrix)

normalize a batch of vector.
"""
function batch_normalize!(s::AbstractMatrix, p::Real=2)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i), p)
    end
    s
end

"""
    batch_normalize

normalize a batch of vector.
"""
function batch_normalize(s::AbstractMatrix, p::Real=2)
    ts = copy(s)
    batch_normalize!(ts, p)
end

"""
    hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general kronecher product form of gates in Hilbert space of `num_bit` qubits.

* `gates` are a list of matrices.
* `start_locs` should have the same length as `gates`, specifing the gates starting positions.
"""
function hilbertkron(num_bit::Int, ops::Vector{<:AbstractMatrix}, start_locs::Vector{Int})
    sizes = [log2dim1(op) for op in ops]
    start_locs = num_bit .- start_locs .- sizes .+ 2

    order = sortperm(start_locs)
    sorted_ops = ops[order]
    sorted_start_locs = start_locs[order]
    num_ids = vcat(sorted_start_locs[1]-1, diff(push!(sorted_start_locs, num_bit+1)) .- sizes[order])

    _wrap_identity(sorted_ops, num_ids)
end

# kron, and wrap matrices with identities.
function _wrap_identity(data_list::Vector{T}, num_bit_list::Vector{Int}) where T<:AbstractMatrix
    length(num_bit_list) == length(data_list) + 1 || throw(ArgumentError())
    ⊗ = kron
    reduce(zip(data_list, num_bit_list[2:end]); init=IMatrix(1 << num_bit_list[1])) do x, y
        x ⊗ y[1] ⊗ IMatrix(1<<y[2])
    end
end

batched_kron(a, b, c, xs...) = Base.afoldl(batched_kron, (batched_kron)((batched_kron)(a,b),c), xs...)

function batched_kron(A::AbstractArray{T, 3}, B::AbstractArray{S, 3}) where {T, S}
    @assert size(A, 3) == size(B, 3) "batch size mismatch"
    C = Array{Base.promote_op(*,T,S), 3}(undef, size(A, 1) * size(B, 1), size(A, 2) * size(B, 2), size(A, 3))
    return batched_kron!(C, A, B)
end

function batched_kron!(C::Array{T, 3}, A::Array{T1, 3}, B::Array{T2, 3}) where {T, T1, T2}
    ptrA = Base.unsafe_convert(Ptr{T}, A)
    ptrB = Base.unsafe_convert(Ptr{T1}, B)
    ptrC = Base.unsafe_convert(Ptr{T2}, C)

    for k in 1:size(C, 3)
        Ak = unsafe_wrap(Matrix{T1}, ptrA, (size(A, 1), size(A, 2)))
        Bk = unsafe_wrap(Matrix{T2}, ptrB, (size(B, 1), size(B, 2)))
        Ck = unsafe_wrap(Matrix{T}, ptrC, (size(C, 1), size(C, 2)))

        kron!(Ck, Ak, Bk)

        ptrA += size(A, 1) * size(A, 2) * sizeof(T)
        ptrB += size(B, 1) * size(B, 2) * sizeof(T)
        ptrC += size(C, 1) * size(C, 2) * sizeof(T)
    end

    return C
end

# NOTE: JuliaLang/julia/pull/31069 includes this function
function kron!(C::AbstractMatrix{T}, A::AbstractMatrix{T1}, B::AbstractMatrix{T2}) where {T,T1,T2}
    @assert !Base.has_offset_axes(A, B)
    m = 1
    @inbounds for j = 1:size(A, 2), l = 1:size(B, 2), i = 1:size(A, 1)
        aij = A[i,j]
        for k = 1:size(B, 1)
            C[m] = aij * B[k,l]
            m += 1
        end
    end
    return C
end


"""
    general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general multi-controlled gates in hilbert space of `num_bit` qubits,

* `projectors` are often chosen as `P0` and `P1` for inverse-Control and Control at specific position.
* `cbits` should have the same length as `projectors`, specifing the controling positions.
* `gates` are a list of controlled single qubit gates.
* `locs` should have the same length as `gates`, specifing the gates positions.
"""
function general_controlled_gates(
    n::Int,
    projectors::Vector{<:AbstractMatrix},
    cbits::Vector{Int},
    gates::Vector{<:AbstractMatrix},
    locs::Vector{Int}
)
    IMatrix(1<<n) - hilbertkron(n, projectors, cbits) +
        hilbertkron(n, vcat(projectors, gates), vcat(cbits, locs))
end

"""
    general_c1_gates(num_bit::Int, projector::AbstractMatrix, cbit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

general (low performance) construction method for control gate on different lines.
"""
general_c1_gates(num_bit::Int, projector::Tp, cbit::Int, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} =
    hilbertkron(num_bit, [IMatrix(2) - projector], [cbit]) + hilbertkron(num_bit, vcat([projector], gates), vcat([cbit], locs))

"""
    rotmat(M::AbstractMatrix, θ::Real)

Returns rotated `M`: ``exp(-\\frac{imθ}{2} M)``.
"""
rotmat(M::AbstractMatrix, θ::Real) = exp(-im * θ/2 * M)


"""
    linop2dense([T=ComplexF64], linear_map!::Function, n::Int) -> Matrix

Returns the dense matrix representation given linear map function.
"""
linop2dense(linear_map!::Function, n::Int) = linop2dense(ComplexF64, linear_map!, n)
linop2dense(::Type{T}, linear_map!::Function, n::Int) where T = linear_map!(Matrix{T}(I, 1<<n, 1<<n))

################### Fidelity ###################

"""
    density_fidelity(ρ1, ρ2)

General fidelity (including mixed states) between two density matrix for qubits.

# Definition

```math
F(ρ, σ)^2 = tr(ρσ) + 2 \\sqrt{det(ρ)det(σ)}
```
"""
function density_fidelity(ρ1::AbstractMatrix, ρ2::AbstractMatrix)
    return sqrt( tr(ρ1 * ρ2) + 2 * sqrt(det(ρ1) * det(ρ2)) )
end

"""
    pure_state_fidelity(v1::Vector, v2::Vector)

fidelity for pure states.
"""
pure_state_fidelity(v1::Vector, v2::Vector) = abs(v1'*v2)

"""
    purification_fidelity(m1::Matrix, m2::Matrix)

Fidelity for mixed states via purification.

Reference:
    http://iopscience.iop.org/article/10.1088/1367-2630/aa6a4b/meta
"""
function purification_fidelity(m1::Matrix, m2::Matrix)
    O = m1'*m2
    return tr(sqrt(O*O'))
end

"""
    rand_unitary([T=ComplexF64], N::Int) -> Matrix

Create a random unitary matrix.
"""
rand_unitary(N::Int) = rand_unitary(ComplexF64, N)
rand_unitary(::Type{T}, N::Int) where T = qr(randn(T, N, N)).Q |> Matrix

"""
    sprand_unitary([T=ComplexF64], N::Int, density) -> SparseMatrixCSC

Create a random sparse unitary matrix.
"""
sprand_unitary(N::Int, density::Real) = sprand_unitary(ComplexF64, N, density)
sprand_unitary(::Type{T}, N::Int, density::Real) where T = SparseMatrixCSC(qr(sprandn(T, N, N, density)).Q)

"""
    rand_hermitian([T=ComplexF64], N::Int) -> Matrix

Create a random hermitian matrix.
"""
rand_hermitian(N::Int) = rand_hermitian(ComplexF64, N)

function rand_hermitian(::Type{T}, N::Int) where T
    A = randn(T, N, N)
    A + A'
end

"""
    sprand_hermitian([T=ComplexF64], N, density)

Create a sparse random hermitian matrix.
"""
sprand_hermitian(N::Int, density) = sprand_hermitian(ComplexF64, N, density)

function sprand_hermitian(::Type{T}, N::Int, density::Real) where T
    A = sprandn(T, N, N, density)
    return A + A'
end

"""
    autostatic(A[; threshold=8])

Staticize dynamic array `A` by a `threshold`.
"""
autostatic(A::AbstractVecOrMat; threshold::Int=8) = length(A) > (1 << threshold) ? A : staticize(A)
