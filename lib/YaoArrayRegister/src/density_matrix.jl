"""
    DensityMatrix(state::AbstractArray{T, 3}; nlevel=2)
    DensityMatrix(state::AbstractMatrix{T}; nlevel=2)

Create a `DensityMatrix` with a state represented by array.
"""
YaoBase.DensityMatrix{D}(state::AbstractMatrix{T}) where {T,D} = DensityMatrix{D,T,typeof(state)}(state)
YaoBase.DensityMatrix(state::AbstractMatrix{T}; nlevel=2) where T = DensityMatrix{nlevel}(state)

"""
    state(ρ::DensityMatrix)

Return the raw state of density matrix `ρ`.
"""
state(ρ::DensityMatrix) = ρ.state

YaoBase.nqubits(ρ::DensityMatrix) = nqudits(state(ρ))
YaoBase.nqudits(ρ::DensityMatrix{D}) where {D} = logdi(size(state(ρ), 1), D)
YaoBase.nactive(ρ::DensityMatrix) = nqudits(ρ)

"""
    density_matrix(reg, qubits)

Get the reduced density matrix on given `locs`. See also [`focus!`](@ref).
"""
function YaoBase.density_matrix(reg::ArrayReg, qubits)
    freg = focus!(copy(reg), qubits)
    return density_matrix(freg)
end
YaoBase.density_matrix(reg::ArrayReg) = DensityMatrix(reg.state * reg.state')
YaoBase.tracedist(dm1::DensityMatrix{D}, dm2::DensityMatrix{D}) where {D} = trnorm(dm1.state .- dm2.state)

# TODO: use batch_broadcast in the future
"""
    probs(ρ)

Returns the probability distribution from a density matrix `ρ`.
"""
YaoBase.probs(m::DensityMatrix) = diag(m.state)

function YaoBase.purify(r::DensityMatrix{D}; num_env::Int = nactive(r)) where {D}
    Ne = D ^ num_env
    Ns = size(r.state, 1)
    R, U = eigen!(r.state)
    state = view(U, :, Ns-Ne+1:Ns) .* sqrt.(abs.(view(R, Ns-Ne+1:Ns)'))
    return ArrayReg{D}(state)
end

# obtaining matrix from Yao.DensityMatrix
LinearAlgebra.Matrix(d::DensityMatrix) = d.state

von_neumann_entropy(dm::DensityMatrix) = von_neumann_entropy(Matrix(dm))
function von_neumann_entropy(dm::AbstractMatrix)
    p = max.(eigvals(dm), eps(real(eltype(dm))))
    return von_neumann_entropy(p)
end
von_neumann_entropy(v::AbstractVector) = -sum(x->x*log(x), v)