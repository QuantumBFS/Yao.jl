## from original YaoAPI
YaoAPI.measure!(postprocess::PostProcess, op, reg::AbstractRegister; kwargs...) =
    measure!(postprocess, op, reg, AllLocs(); kwargs...)
YaoAPI.measure!(postprocess::PostProcess, reg::AbstractRegister, locs; kwargs...) =
    measure!(postprocess, ComputationalBasis(), reg, locs; kwargs...)
YaoAPI.measure!(postprocess::PostProcess, reg::AbstractRegister; kwargs...) =
    measure!(postprocess, ComputationalBasis(), reg, AllLocs(); kwargs...)
YaoAPI.measure!(op, reg::AbstractRegister, args...; kwargs...) =
    measure!(NoPostProcess(), op, reg, args...; kwargs...)
YaoAPI.measure!(reg::AbstractRegister, args...; kwargs...) =
    measure!(NoPostProcess(), reg, args...; kwargs...)

YaoAPI.measure(op, reg::AbstractRegister; kwargs...) = measure(op, reg, AllLocs(); kwargs...)
YaoAPI.measure(reg::AbstractRegister, locs; kwargs...) =
    measure(ComputationalBasis(), reg, locs; kwargs...)
YaoAPI.measure(reg::AbstractRegister; kwargs...) =
    measure(ComputationalBasis(), reg, AllLocs(); kwargs...)

# focus! to specify locations, we that we only need to consider full-space measure in the future.
function YaoAPI.measure!(
    postprocess::PostProcess,
    op,
    reg::AbstractRegister,
    locs;
    kwargs...,
)
    nbit = nactive(reg)
    focus!(reg, locs)
    res = measure!(postprocess, op, reg, AllLocs(); kwargs...)
    if postprocess isa RemoveMeasured
        relax!(reg; to_nactive = nbit - length(locs))
    else
        relax!(reg, locs; to_nactive = nbit)
    end
    res
end

function YaoAPI.measure(op, reg::AbstractRegister, locs; kwargs...)
    nbit = nactive(reg)
    focus!(reg, locs)
    res = measure(op, reg, AllLocs(); kwargs...)
    relax!(reg, locs; to_nactive = nbit)
    res
end

function _measure(rng::AbstractRNG, base, pl::AbstractVector, nshots::Int)
    sample(rng, base, Weights(pl), nshots)
end

function _measure(rng::AbstractRNG, base, pl::AbstractMatrix, nshots::Int)
    B = size(pl, 2)
    res = Matrix{eltype(base)}(undef, nshots, B)
    for ib = 1:B
        @inbounds res[:, ib] = _measure(rng, base, view(pl, :, ib), nshots)
    end
    return res
end

YaoAPI.measure(
    ::ComputationalBasis,
    reg::ArrayReg,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
) = _measure(rng, basis(reg), reg |> probs, nshots)

YaoAPI.measure(
    ::ComputationalBasis,
    reg::DensityMatrix,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
) = _measure(rng, basis(reg), reg |> probs, nshots)

function YaoAPI.measure(
    ::ComputationalBasis,
    reg::BatchedArrayReg,
    ::AllLocs;
    nshots::Int = 1,
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims = 2), dims = 2)
    return _measure(rng, basis(reg), pl, nshots)
end

function YaoAPI.measure!(
    ::YaoAPI.RemoveMeasured,
    ::ComputationalBasis,
    reg::AbstractArrayReg{D},
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
) where {D}
    state = reg |> rank3
    B = size(state, 3)
    nstate = similar(reg.state, D ^ nremain(reg), B)
    pl = dropdims(sum(state .|> abs2, dims = 2), dims = 2)
    res = Vector{eltype(basis(reg))}(undef, B)
    @inbounds for ib = 1:B
        ires = _measure(rng, basis(reg), view(pl, :, ib), 1)[]
        # notice ires is `BitStr` type, can be use as indices directly.
        nstate[:, ib] = view(state, Int64(ires) + 1, :, ib) ./ sqrt(pl[Int64(ires)+1, ib])
        res[ib] = ires
    end
    reg.state = reshape(nstate, 1, :)
    return reg isa ArrayReg ? res[] : res
end

function YaoAPI.measure!(
    ::YaoAPI.NoPostProcess,
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

function YaoAPI.measure!(
    rst::YaoAPI.ResetTo,
    ::ComputationalBasis,
    reg::AbstractArrayReg,
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    state = rank3(reg)
    M, N, B = size(state)
    nstate = zero(state)
    res = measure!(YaoAPI.RemoveMeasured(), reg; rng = rng)
    nstate[Int(rst.x)+1, :, :] = reshape(reg.state, :, B)
    reg.state = reshape(nstate, M, N * B)
    return res
end

import YaoAPI: select, select!
select(r::AbstractArrayReg, bits::AbstractVector{T}) where {T<:Integer} =
    arrayreg(r.state[Int64.(bits).+1, :]; nbatch=nbatch(r), nlevel=nlevel(r))
select(r::AbstractArrayReg, bit::Integer) = select(r, [bit])
select!(bits...) = @λ(register -> select!(register, bits...))

function select!(r::AbstractArrayReg, bits::AbstractVector{T}) where {T<:Integer}
    r.state = r.state[Int64.(bits).+1, :]
    return r
end

select!(r::AbstractArrayReg, bit::Integer) = select!(r, [bit])
