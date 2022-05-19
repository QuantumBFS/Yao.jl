YaoAPI.DensityMatrix{D}(state::AbstractMatrix{T}) where {T,D} = DensityMatrix{D,T,typeof(state)}(state)
YaoAPI.DensityMatrix(state::AbstractMatrix{T}; nlevel=2) where T = DensityMatrix{nlevel}(state)

"""
    state(ρ::DensityMatrix) -> Matrix

Return the raw state of density matrix `ρ`.
"""
state(ρ::DensityMatrix) = ρ.state
Base.copy(ρ::DensityMatrix{D}) where D = DensityMatrix{D}(copy(ρ.state))
Base.:(==)(ρ::DensityMatrix, σ::DensityMatrix) = nlevel(ρ) == nlevel(σ) && ρ.state == σ.state

YaoAPI.nqubits(ρ::DensityMatrix) = nqudits(ρ)
YaoAPI.nqudits(ρ::DensityMatrix{D}) where {D} = logdi(size(state(ρ), 1), D)
YaoAPI.nactive(ρ::DensityMatrix) = nqudits(ρ)

function YaoAPI.density_matrix(reg::ArrayReg, qubits)
    freg = focus!(copy(reg), qubits)
    return density_matrix(freg)
end
YaoAPI.density_matrix(reg::ArrayReg{D}) where D = DensityMatrix{D}(reg.state * reg.state')
YaoAPI.tracedist(dm1::DensityMatrix{D}, dm2::DensityMatrix{D}) where {D} = trace_norm(dm1.state .- dm2.state)

# TODO: use batch_broadcast in the future
"""
    probs(ρ) -> Vector

Returns the probability distribution from a density matrix `ρ`.
"""
YaoAPI.probs(m::DensityMatrix) = diag(m.state)

function YaoAPI.fidelity(m::DensityMatrix, n::DensityMatrix)
    return density_matrix_fidelity(m.state, n.state)
end

function YaoAPI.purify(r::DensityMatrix{D}; num_env::Int = nactive(r)) where {D}
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