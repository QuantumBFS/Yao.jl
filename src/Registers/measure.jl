export measure, measure!, measure_remove!, measure_reset!, select, select!
using StatsBase

@static if VERSION < v"0.7+"
    # select is deprecated
    # we can be a pirate anyway
    import Base: select, select!
end

_measure(pl::AbstractVector, ntimes::Int) = sample(0:length(pl)-1, Weights(pl), ntimes)
function _measure(pl::AbstractMatrix, ntimes::Int)
    B = size(pl, 2)
    res = Matrix{Int}(undef, ntimes, B)
    for ib=1:B
        @inbounds res[:,ib] = _measure(view(pl,:,ib), ntimes)
    end
    res
end

"""
    measure(register, [n=1]) -> Vector

measure active qubits for `n` times.
"""
measure(reg::AbstractRegister{1}, nshot::Int=1) = _measure(reg |> probs, nshot)
function measure(reg::AbstractRegister{B}, nshot::Int=1) where B
    pl = dropdims(sum(reg |> rank3 .|> abs2, dims=2), dims=2)
    _measure(pl, nshot)
end

"""
    measure_remove!(register) -> Int

measure the active qubits of this register and remove them.
"""
function measure_remove!(reg::AbstractRegister{B}) where B
    state = reg |> rank3
    nstate = similar(reg.state, 1<<nremain(reg), B)
    pl = dropdims(sum(state .|> abs2, dims=2), dims=2)
    res = Vector{Int}(undef, B)
    for ib = 1:B
        @inbounds ires = _measure(view(pl, :, ib), 1)[]
        @inbounds nstate[:,ib] = view(state, ires+1,:,ib)./sqrt(pl[ires+1, ib])
        @inbounds res[ib] = ires
    end
    reg.state = reshape(nstate,1,:)
    res
end

"""
    measure!(reg::AbstractRegister) -> Int

measure and collapse to result state.
"""
function measure!(reg::AbstractRegister{B}) where B
    state = reg |> rank3
    nstate = zero(state)
    res = measure_remove!(reg)
    _nstate = reshape(reg.state, :, B)
    for ib in 1:B
        @inbounds nstate[res[ib]+1, :, ib] = view(_nstate, :,ib)
    end
    reg.state = reshape(nstate, size(state, 1), :)
    res
end

"""
    measure_and_reset!(reg::AbstractRegister, [mbits]; val=0) -> Int

measure and set the register to specific value.
"""
function measure_reset!(reg::AbstractRegister{B}; val::Integer=0) where B
    state = reg |> rank3
    M, N, B1 = state |> size
    nstate = zero(state)
    res = measure_remove!(reg)
    nstate[val+1, :, :] = reshape(reg.state, :, B)
    reg.state = reshape(nstate, M, N*B)
    res
end

function measure_reset!(reg::AbstractRegister, mbits; val::Integer=0) where {B, T, C}
    local res
    focus!(reg, mbits) do reg_focused
        res = measure_reset!(reg_focused, val=val)
        reg_focused
    end
    res
end

"""
    select!(reg::AbstractRegister, b::Integer) -> AbstractRegister
    select!(b::Integer) -> Function

select specific component of qubit, the inplace version, the currified version will return a Function.

e.g.
`select!(reg, 0b110)` will select the subspace with (focused) configuration `110`.
After selection, the focused qubit space is 0, so you may want call `relax!` manually.
"""
function select!(reg::AbstractRegister{B}, bits) where B
    reg.state = reg.state[[bits...].+1, :]
    reg
end
select!(bits::Integer...) = reg::AbstractRegister -> select!(reg, bits)

"""
    select(reg::AbstractRegister, b::Integer) -> AbstractRegister

the non-inplace version of [`select!`](@ref) function.
"""
select(reg::DefaultRegister{B}, bits) where B = DefaultRegister{B}(reg.state[[bits...].+1, :])
