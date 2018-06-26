struct DensityMatrix{B, T, MT<:AbstractArray{T, 3}}
    state::MT
end

DensityMatrix(state::MT) where {T, MT<:AbstractArray{T, 3}} = DensityMatrix{size(state, 3), T, MT}(state)
DensityMatrix(state::MT) where {T, MT<:AbstractArray{T, 2}} = (state=state[:,:,1:1]; DensityMatrix{1, T, typeof(state)}(state))

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
