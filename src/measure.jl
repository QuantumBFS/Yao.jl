using StatsBase, StaticArrays, BitBasis, Random
export measure,
    measure!,
    measure_remove!,
    measure_collapseto!,
    select,
    select!

_measure(rng::AbstractRNG, pl::AbstractVector, nshots::Int) = sample(rng, 0:length(pl)-1, Weights(pl), nshots)
function _measure(rng::AbstractRNG, pl::AbstractMatrix, nshots::Int)
    B = size(pl, 2)
    res = Matrix{Int}(undef, nshots, B)
    for ib=1:B
        @inbounds res[:,ib] = _measure(rng, view(pl,:,ib), nshots)
    end
    return res
end

YaoBase.measure(rng::AbstractRNG, ::ComputationalBasis, reg::ArrayReg{1}, ::AllLocs; nshots::Int=1) = _measure(rng, reg |> probs, nshots)

function YaoBase.measure(rng::AbstractRNG, ::ComputationalBasis, reg::ArrayReg{B}, ::AllLocs; nshots::Int=1) where B
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims=2), dims=2)
    return _measure(rng, pl, nshots)
end

function YaoBase.measure_remove!(rng::AbstractRNG, ::ComputationalBasis, reg::ArrayReg{B}, ::AllLocs) where B
    state = reg |> rank3
    nstate = similar(reg.state, 1<<nremain(reg), B)
    pl = dropdims(sum(state .|> abs2, dims=2), dims=2)
    res = Vector{Int}(undef, B)
    @inbounds for ib = 1:B
        ires = _measure(rng, view(pl, :, ib), 1)[]
        nstate[:,ib] = view(state, ires+1,:,ib)./sqrt(pl[ires+1, ib])
        res[ib] = ires
    end
    reg.state = reshape(nstate,1,:)
    return res
end

function YaoBase.measure!(rng::AbstractRNG, ::ComputationalBasis, reg::ArrayReg{B}, ::AllLocs) where B
    state = reg |> rank3
    nstate = zero(state)
    res = measure_remove!(rng, reg)
    _nstate = reshape(reg.state, :, B)
    for ib in 1:B
        @inbounds nstate[res[ib]+1, :, ib] .= view(_nstate, :,ib)
    end
    reg.state = reshape(nstate, size(state, 1), :)
    return res
end

function YaoBase.measure_collapseto!(rng::AbstractRNG, ::ComputationalBasis, reg::ArrayReg{B}, ::AllLocs; config::Integer=0) where B
    state = rank3(reg)
    M, N, B1 = size(state)
    nstate = zero(state)
    res = measure_remove!(rng, reg)
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
