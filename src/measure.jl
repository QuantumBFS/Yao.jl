using StatsBase, StaticArrays
export measure,
    measure!,
    measure_remove!,
    measure_collapseto!,
    select,
    select!

_measure(pl::AbstractVector, ntimes::Int) = sample(0:length(pl)-1, Weights(pl), ntimes)
function _measure(pl::AbstractMatrix, ntimes::Int)
    B = size(pl, 2)
    res = Matrix{Int}(undef, ntimes, B)
    for ib=1:B
        @inbounds res[:,ib] = _measure(view(pl,:,ib), ntimes)
    end
    return res
end

YaoBase.measure(reg::ArrayReg{1}; ntimes::Int=1) = _measure(reg |> probs, ntimes)

function YaoBase.measure(reg::ArrayReg{B}; ntimes::Int=1) where B
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims=2), dims=2)
    return _measure(pl, ntimes)
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
    state = reg |> rank3
    M, N, B1 = state |> size
    nstate = zero(state)
    res = measure_remove!(reg)
    nstate[config+1, :, :] = reshape(reg.state, :, B)
    reg.state = reshape(nstate, M, N*B)
    return res
end

YaoBase.select(r::ArrayReg{B}, bits...) = ArrayReg{B}(reg.state[[bits...].+1, :])

function YaoBase.select!(r::ArrayReg, bits)
    to_address(x::Integer) = x + 1
    to_address(x) = x
    r.state = r.state[map(to_address, bits), :]
    return r
end

function YaoBase.select!(r::ArrayReg, bits::Integer)
    r.state = reshape(r.state[bits+1, :], 1, :)
    return r
end

YaoBase.select!(r::ArrayReg, bits::BitStr) = select!(r, bits.val)
