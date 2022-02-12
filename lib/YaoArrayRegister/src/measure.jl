using StatsBase, StaticArrays, BitBasis, Random
export measure, measure!, select, select!

function _measure(rng::AbstractRNG, pl::AbstractVector, nshots::Int)
    N = log2i(length(pl))
    sample(rng, basis(BitStr64{N}), Weights(pl), nshots)
end

function _measure(rng::AbstractRNG, pl::AbstractMatrix, nshots::Int)
    B = size(pl, 2)
    res = Matrix{BitStr64{log2i(size(pl, 1))}}(undef, nshots, B)
    for ib = 1:B
        @inbounds res[:, ib] = _measure(rng, view(pl, :, ib), nshots)
    end
    return res
end

YaoBase.measure(
    ::ComputationalBasis,
    reg::ArrayReg,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
) = _measure(rng, reg |> probs, nshots)

function YaoBase.measure(
    ::ComputationalBasis,
    reg::BatchedArrayReg,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims = 2), dims = 2)
    return _measure(rng, pl, nshots)
end

function YaoBase.measure!(
    ::YaoBase.RemoveMeasured,
    ::ComputationalBasis,
    reg::AbstractArrayReg{D},
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
) where {D}
    state = reg |> rank3
    B = size(state, 3)
    nstate = similar(reg.state, D ^ nremain(reg), B)
    pl = dropdims(sum(state .|> abs2, dims = 2), dims = 2)
    res = Vector{BitStr64{nactive(reg)}}(undef, B)
    @inbounds for ib = 1:B
        ires = _measure(rng, view(pl, :, ib), 1)[]
        # notice ires is `BitStr` type, can be use as indices directly.
        nstate[:, ib] = view(state, Int64(ires) + 1, :, ib) ./ sqrt(pl[Int64(ires)+1, ib])
        res[ib] = ires
    end
    reg.state = reshape(nstate, 1, :)
    return reg isa ArrayReg ? res[] : res
end

function YaoBase.measure!(
    ::YaoBase.NoPostProcess,
    ::ComputationalBasis,
    reg::AbstractArrayReg,
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    state = reg |> rank3
    M, N, B = size(state)
    nstate = zero(state)
    res = measure!(RemoveMeasured(), reg; rng = rng)
    _nstate = reshape(reg.state, :, B)
    indices = Int64.(res) .+ 1
    for ib = 1:B
        @inbounds nstate[indices[ib], :, ib] .= view(_nstate, :, ib)
    end
    reg.state = reshape(nstate, M, :)
    return res
end

function YaoBase.measure!(
    rst::YaoBase.ResetTo,
    ::ComputationalBasis,
    reg::AbstractArrayReg,
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    state = rank3(reg)
    M, N, B = size(state)
    nstate = zero(state)
    res = measure!(YaoBase.RemoveMeasured(), reg; rng = rng)
    nstate[Int(rst.x)+1, :, :] = reshape(reg.state, :, B)
    reg.state = reshape(nstate, M, N * B)
    return res
end

import YaoBase: select, select!
select(r::AbstractArrayReg, bits::AbstractVector{T}) where {T<:Integer} =
    arrayreg(r.state[Int64.(bits).+1, :]; nbatch=nbatch(r), nlevel=nlevel(r))
select(r::AbstractArrayReg, bit::Integer) = select(r, [bit])

function select!(r::AbstractArrayReg, bits::AbstractVector{T}) where {T<:Integer}
    r.state = r.state[Int64.(bits).+1, :]
    return r
end

select!(r::AbstractArrayReg, bit::Integer) = select!(r, [bit])
