"""
    SuperOp{D,T,MT<:AbstractMatrix{T}} <: AbstractQuantumChannel{D}

    SuperOp{D}(n::Int, superop::AbstractMatrix)
    SuperOp(superop::AbstractMatrix; nlevel::Int=2)

Superoperator representation of a quantum channel. Its matrix size is `D^(2n) × D^(2n)`, where `D` is the dimension of the system and `n` is the number of qubits.
A superoperator is a linear map from the space of density matrices to itself.

### Fields
- `n::Int`: the number of qubits
- `superop::AbstractMatrix`: the superoperator matrix


## Arguments
- `nlevel::Int`: the number of levels of the superoperator, default to 2 for a single qubit channel.
"""
struct SuperOp{D,T,MT<:AbstractMatrix{T}} <: AbstractQuantumChannel{D}
    n::Int
    superop::MT
    function SuperOp{D}(n::Int, superop::AbstractMatrix) where D
        @assert size(superop, 1) == size(superop, 2) == D^(2n) "The size of the superoperator matrix must be D^(2n) × D^(2n), given D=$D and n=$n, but got $(size(superop))"
        new{D,eltype(superop),typeof(superop)}(n, superop)
    end
end
function SuperOp{D}(superop::AbstractMatrix) where D
    n = logdi(size(superop, 1), 2*D)
    SuperOp{D}(n, superop)
end
SuperOp(superop::AbstractMatrix) = SuperOp{2}(superop)

nqudits(uc::SuperOp) = uc.n
subblocks(::SuperOp) = ()

print_block(io::IO, x::SuperOp) = print(io, "SuperOp{$(nqudits(x))}($(x.superop))")

function noisy_instruct!(rho::DensityMatrix{D,T}, x::SuperOp, locs) where {D,T}
    reg = ArrayReg{D}(vec(rho.state))
    instruct!(reg, x.superop, (locs..., (locs .+ nqudits(rho))...))
    return rho
end
function YaoAPI.unsafe_apply!(rho::DensityMatrix{D,T}, x::SuperOp) where {D,T}
    reg = ArrayReg{D}(vec(rho.state))
    unsafe_apply!(reg, GeneralMatrixBlock{D}(2*x.n, 2*x.n, x.superop))
    return rho
end

function cache_key(x::SuperOp)
    return hash(x.n, hash(x.superop))
end
function Base.:(==)(lhs::SuperOp, rhs::SuperOp)
    return (lhs.n == rhs.n) && (lhs.superop == rhs.superop)
end
Base.isapprox(x::SuperOp, y::SuperOp; kwargs...) = isapprox(x.superop, y.superop; kwargs...)
Base.adjoint(x::SuperOp{D}) where D = SuperOp{D}(x.n, adjoint(x.superop))

# convert block to superop
function SuperOp(::Type{T}, x::AbstractBlock{D}) where {D,T}
    m = mat(T, x)
    SuperOp{D}(kron(conj(m), m))
end
SuperOp(x::AbstractBlock{D}) where D = SuperOp(Complex{Float64}, x)