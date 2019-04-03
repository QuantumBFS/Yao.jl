using StatsBase, StaticArrays, BitBasis
export measure,
    measure!,
    measure_remove!,
    measure_collapseto!,
    select,
    select!

_measure(pl::AbstractVector, nshots::Int) = sample(0:length(pl)-1, Weights(pl), nshots)
function _measure(pl::AbstractMatrix, nshots::Int)
    B = size(pl, 2)
    res = Matrix{Int}(undef, nshots, B)
    for ib=1:B
        @inbounds res[:,ib] = _measure(view(pl,:,ib), nshots)
    end
    return res
end

YaoBase.measure(reg::ArrayReg{1}; nshots::Int=1) = _measure(reg |> probs, nshots)

function YaoBase.measure(reg::ArrayReg{B}; nshots::Int=1) where B
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims=2), dims=2)
    return _measure(pl, nshots)
end

function YaoBase.measure_remove!(reg::ArrayReg{B}) where B
    state = reg |> rank3
    nstate = similar(reg.state, 1<<nremain(reg), B)
    pl = dropdims(sum(state .|> abs2, dims=2), dims=2)
    res = Vector{Int}(undef, B)
    @inbounds for ib = 1:B
        ires = _measure(view(pl, :, ib), 1)[]
        nstate[:,ib] = view(state, ires+1,:,ib)./sqrt(pl[ires+1, ib])
        res[ib] = ires
    end
    reg.state = reshape(nstate,1,:)
    return res
end

function YaoBase.measure!(reg::ArrayReg{B}) where B
    state = reg |> rank3
    nstate = zero(state)
    res = measure_remove!(reg)
    _nstate = reshape(reg.state, :, B)
    for ib in 1:B
        @inbounds nstate[res[ib]+1, :, ib] .= view(_nstate, :,ib)
    end
    reg.state = reshape(nstate, size(state, 1), :)
    return res
end

function YaoBase.measure_collapseto!(reg::ArrayReg{B}; config::Integer=0) where B
    state = rank3(reg)
    M, N, B1 = size(state)
    nstate = zero(state)
    res = measure_remove!(reg)
    nstate[config+1, :, :] = reshape(reg.state, :, B)
    reg.state = reshape(nstate, M, N*B)
    return res
end

YaoBase.select(r::ArrayReg{B}, bits) where B = ArrayReg{B}(r.state[map(to_location, bits), :])
YaoBase.select(r::ArrayReg{B}, bit::Union{Integer, BitStr}) where B = select(r, [bit])

function YaoBase.select!(r::ArrayReg, bits)
    r.state = r.state[map(to_location, bits), :]
    return r
end

function YaoBase.select!(r::ArrayReg, bits::Integer)
    r.state = reshape(r.state[bits+1, :], 1, :)
    return r
end

YaoBase.select!(r::ArrayReg, bits::BitStr) = select!(r, bits.val)
