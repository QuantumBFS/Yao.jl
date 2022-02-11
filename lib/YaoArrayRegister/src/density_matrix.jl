"""
    DensityMatrix(state::AbstractArray{T, 3}; nlevel=2)
    DensityMatrix(state::AbstractMatrix{T}; nlevel=2)

Create a `DensityMatrix` with a state represented by array.
"""
YaoBase.DensityMatrix(state::MT; nlevel=2) where {T,MT<:AbstractArray{T,3}} =
    DensityMatrix{size(state, 3),nlevel,T,MT}(state)
YaoBase.DensityMatrix(state::AbstractMatrix; nlevel=2) =
    DensityMatrix(reshape(state, size(state)..., 1); nlevel=nlevel)

"""
    state(ρ::DensityMatrix)

Return the raw state of density matrix `ρ`.
"""
state(ρ::DensityMatrix) = ρ.state

YaoBase.nqubits(ρ::DensityMatrix) = nqudits(state(ρ))
YaoBase.nqudits(ρ::DensityMatrix{B,D}) where {B,D} = logdi(size(state(ρ), 1), D)
YaoBase.nactive(ρ::DensityMatrix) = nqudits(ρ)

"""
    density_matrix(reg, qubits)

Get the reduced density matrix on given `locs`. See also [`focus!`](@ref).
"""
function YaoBase.density_matrix(reg::ArrayReg, qubits)
    freg = focus!(copy(reg), qubits)
    return density_matrix(freg)
end
YaoBase.density_matrix(reg::ArrayReg{1}) = DensityMatrix(reg.state * reg.state')
function YaoBase.density_matrix(reg::ArrayReg{B}) where {B}
    M = size(reg.state, 1)
    s = reshape(reg |> state, M, :, B)
    out = similar(s, M, M, B)
    for b = 1:B
        @inbounds @views out[:, :, b] = s[:, :, b] * s[:, :, b]'
    end
    return DensityMatrix(out)
end

YaoBase.tracedist(dm1::DensityMatrix{B,D}, dm2::DensityMatrix{B,D}) where {B,D} =
    map(b -> trnorm(dm1.state[:, :, b] - dm2.state[:, :, b]), 1:B)

# TODO: use batch_broadcast in the future
"""
    probs(ρ)

Returns the probability distribution from a density matrix `ρ`.
"""
function YaoBase.probs(m::DensityMatrix{B,D,T}) where {B,D,T}
    res = zeros(T, size(m.state, 1), B)
    for i = 1:B
        @inbounds res[:, B] = diag(view(m.state, :, :, i))
    end
    return res
end

YaoBase.probs(m::DensityMatrix{1}) = diag(view(m.state, :, :, 1))

function YaoBase.purify(r::DensityMatrix{B,D}; num_env::Int = nactive(r)) where {B,D}
    Ne = D ^ num_env
    Ns = size(r.state, 1)
    state = similar(r.state, Ns, Ne, B)
    for ib = 1:B
        R, U = eigen!(r.state[:, :, ib])
        state[:, :, ib] .= view(U, :, Ns-Ne+1:Ns) .* sqrt.(abs.(view(R, Ns-Ne+1:Ns)'))
    end
    return ArrayReg(state)
end

# obtaining matrix from Yao.DensityMatrix{1}, `1` is the batch size.
LinearAlgebra.Matrix(d::DensityMatrix{1}) = dropdims(d.state, dims = 3)

von_neumann_entropy(dm::DensityMatrix{1}) = von_neumann_entropy(Matrix(dm))
function von_neumann_entropy(dm::AbstractMatrix)
    p = max.(eigvals(dm), eps(real(eltype(dm))))
    return von_neumann_entropy(p)
end
von_neumann_entropy(v::AbstractVector) = -sum(x->x*log(x), v)

function von_neumann_entropy(d::DensityMatrix{B}) where B
    map(1:B) do ib
        von_neumann_entropy(view(d.state,:,:,ib))
    end
end