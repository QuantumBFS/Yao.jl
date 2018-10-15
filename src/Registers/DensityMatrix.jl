"""
    DensityMatrix{B, T, MT<:AbstractArray{T, 3}}
    DensityMatrix(state) -> DensityMatrix

Density Matrix.
"""
struct DensityMatrix{B, T, MT<:AbstractArray{T, 3}}
    state::MT
end

DensityMatrix(state::MT) where {T, MT<:AbstractArray{T, 3}} = DensityMatrix{size(state, 3), T, MT}(state)
DensityMatrix(state::MT) where {T, MT<:AbstractArray{T, 2}} = (state=state[:,:,1:1]; DensityMatrix{1, T, typeof(state)}(state))

"""
    density_matrix(register)

Returns the density matrix of this register.
"""
function density_matrix end

"""
    ρ(register)

Returns the density matrix of this register.
"""
const ρ = density_matrix

density_matrix(reg::DefaultRegister{1}) = DensityMatrix(reg.state*reg.state')

function density_matrix(reg::DefaultRegister{B}) where B
    M = size(reg.state, 1)
    s = reshape(reg |> state, M, :, B)
    out = similar(s, M, M, B)
    for b in 1:B
        @inbounds @views out[:,:,b] = s[:,:,b]*s[:,:,b]'
    end
    DensityMatrix(out)
end
nbatch(dm::DensityMatrix{B}) where B = B

"""
    tracedist(dm1::DensityMatrix{B}, dm2::DensityMatrix{B}) -> Vector

Return trace distance between two density matrices.
"""
tracedist(dm1::DensityMatrix{B}, dm2::DensityMatrix{B}) where B = map(b->norm(dm1.state[:,:,b] - dm2.state[:,:,b]), 1:B)

"""
    probs(dm::DensityMatrix{B, T}) where {B,T}

Return probability from density matrix.
"""
function probs(dm::DensityMatrix{B, T}) where {B,T}
    res = zeros(T, size(dm.state, 1), B)
    for i=1:B
        @inbounds res[:,B] = diag(view(dm.state, :,:,i))
    end
    res
end
