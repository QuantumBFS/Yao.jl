import YaoBase: measure!, measure
using LinearAlgebra: eigen!

"""
    eigenbasis(op::AbstractBlock{N})

Return the `eigenvalue` and `eigenvectors` of target operator.
By applying `eigenvector`' to target state,
one can swith the basis to the eigenbasis of this operator.
However, `eigenvalues` does not have a specific form.
"""
function eigenbasis(op::AbstractBlock{N}) where {N}
    m = mat(op)
    if m isa Diagonal || m isa IMatrix
        op, IdentityGate{N}()
    else
        E, V = eigen!(Matrix(m))
        matblock(Diagonal(E)), matblock(V)
    end
end

for BT in []
    @eval function eigenbasis(op::$BT)
        @warn "eigenbasis on blocktype `$($BT)` calls into the fallback implementation, which might be slow. Try using `kron`, `repeat` if items commute to each oher."
        invoke(eigenbasis, Tuple{AbstractBlock}, op)
    end
end

"""
Return true if operators commute to each other.
"""
function simple_commute_eachother(ops::Vector{<:AbstractBlock{N}}) where {N}
    occ = zeros(Bool, N)
    for op in ops
        for i in occupied_locs(op)
            if occ[i]
                return false
            else
                occ[i] = true
            end
        end
    end
    return true
end

function eigenbasis(op::ChainBlock{N}) where {N}
    # detect commute operators
    if simple_commute_eachother(subblocks(op))
        E = chain(N)
        blks = chain(N)
        for b in subblocks(op)
            Ei, Vi = eigenbasis(b)
            push!(E, Ei)
            push!(blks, Vi)
        end
        return E, blks
    else
        if N > 5
            @warn "eigenbasis on blocktype `ChainBlock` (size $N) calls into the fallback implementation, which might be slow. Try using `kron`, `repeat` if items commute to each oher. If this behavior is not what you expected, please file an issue here: https://github.com/QuantumBFS/Yao.jl/issues."
        end
        invoke(eigenbasis, Tuple{AbstractBlock}, op)
    end
end


for GT in [:PutBlock, :RepeatedBlock, :ControlBlock, :Daggered]
    @eval function eigenbasis(op::$GT)
        E, V = eigenbasis(content(op))
        chcontent(op, E), chcontent(op, V)
    end
end

for GT in [:RotationGate, :TimeEvolution, :Scale]
    @eval function eigenbasis(op::$GT)
        E, V = eigenbasis(content(op))
        chcontent(op, E), V
    end
end

for GT in [:CachedBlock]
    @eval function eigenbasis(op::$GT)
        eigenbasis(content(op))
    end
end

function eigenbasis(op::KronBlock{N}) where {N}
    E = []
    blks = []
    for (k, b) in op
        Ei, Vi = eigenbasis(b)
        push!(E, k => Ei)
        push!(blks, k => Vi)
    end
    kron(N, E...), kron(N, blks...)
end

function eigenbasis(op::XGate)
    Z, H
end

function eigenbasis(op::YGate)
    Z, ConstGate.S * H
end

function measure!(
    postprocess::NoPostProcess,  # operator measuring does not allow removing bits or resetting vaules.
    op::AbstractBlock,
    reg::AbstractRegister,
    locs::AllLocs;
    kwargs...,
)
    _check_msize(op, reg, locs)
    E, V = eigenbasis(op)
    res = measure!(postprocess, BlockedBasis(diag(mat(E))), reg |> V', locs; kwargs...)
    apply!(reg, V)
    return res
end

# `BlockedBasis` is for measuring operators on its eigen basis, where a `block` is a subspace with the same eigenvalue.
# * `perm` is the permutation that permute the basis by the ascending order of eigenvalues,
# * `values` are eigenvalues of target observable for each block,
# * `block_ptr` is the pointers for blocks, e.g. to index block `i`, one can use `block_ptr[i]:block_ptr[i-1]`, or `subblock(blockbasis, i)` for short.
struct BlockedBasis{VT}
    perm::Vector{Int}
    values::VT
    block_ptr::Vector{Int}
end

subblock(bb::BlockedBasis, i::Int) = bb.block_ptr[i]:bb.block_ptr[i+1]-1
nblocks(bb::BlockedBasis) = length(bb.block_ptr)-1

function BlockedBasis(values::AbstractVector{T}) where T
    if length(values) == 1
        return BlockedBasis([1], values, [1,2])
    elseif length(values) == 0
        return BlockedBasis([], values, [1])
    end
    order = sortperm(values; by=real)
    values = values[order]
    vpre = values[1]
    block_ptr = [1]
    unique_values = [vpre]
    k = 1
    for i=2:length(values)
        v = values[i]
        if !isapprox(v, vpre)  # use approx in order to ignore the round off error
            k+=1
            push!(block_ptr, i)
            push!(unique_values, v)
        end
        vpre = v
    end
    push!(block_ptr, length(values)+1)
    return BlockedBasis(order, unique_values, block_ptr)
end

function YaoBase.measure!(
    ::NoPostProcess,
    bb::BlockedBasis,
    reg::ArrayReg{B,T},
    ::AllLocs;
    rng::AbstractRNG = Random.GLOBAL_RNG,
) where {B,T}
    state = (reg |> rank3)[bb.perm,:,:]  # permute to make eigen values sorted
    pl = dropdims(sum(abs2, state, dims = 2), dims = 2)
    pl_block = zeros(eltype(pl),nblocks(bb),B)
    for ib=1:B
        for i=1:nblocks(bb)
            for k in subblock(bb, i)
                pl_block[i,ib] += pl[k,ib]
            end
        end
    end
    res = Vector{Int}(undef, B)
    @inbounds @views for ib = 1:B
        ires = sample(rng, 1:nblocks(bb), Weights(pl_block[:,ib]))
        # notice ires is `BitStr` type, can be use as indices directly.
        range = subblock(bb,ires)
        state[range,:,ib] ./= sqrt(pl_block[ires, ib])
        state[1:range.start-1,:,ib] .= zero(T)
        state[range.stop+1:size(state,1),:,ib] .= zero(T)
        res[ib] = ires
    end
    # undo permute and assign back
    _state = reshape(state, 1<<nactive(reg), :)
    rstate = reshape(reg.state, 1<<nactive(reg), :)
    for j = 1:size(rstate,2)
        for i=1:size(rstate,1)
            rstate[bb.perm[i],j] = _state[i,j]
        end
    end
    return B == 1 ? bb.values[res[]] : bb.values[res]
end

function measure(op::AbstractBlock, reg::AbstractRegister, locs::AllLocs; kwargs...)
    _check_msize(op, reg, locs)
    E, V = eigenbasis(op)
    res = measure(ComputationalBasis(), copy(reg) |> V', locs; kwargs...)
    diag(mat(E))[Int64.(res).+1]
end

render_mlocs(alllocs::AllLocs, locs) = locs
render_mlocs(alllocs, locs) = alllocs[locs]

function _check_msize(op, reg, locs)
    if (locs isa AllLocs ? nactive(reg) : length(locs)) != nqubits(op)
        throw(
            QubitMismatchError(
                "operator of size $(nqubits(op)) does not match register size $(nactive(reg))",
            ),
        )
    end
end

function measure(op::Scale, reg::AbstractRegister, locs::AllLocs; kwargs...)
    factor(op) .* measure(content(op), reg, locs; kwargs...)
end

function measure(op::CachedBlock, reg::AbstractRegister, locs::AllLocs; kwargs...)
    measure(content(op), reg, locs; kwargs...)
end

function measure(op::Daggered, reg::AbstractRegister, locs::AllLocs; kwargs...)
    conj(measure(content(op), reg, locs; kwargs...))
end

function measure(ab::Add, reg::AbstractRegister, locs::AllLocs; kwargs...)
    sum(subblocks(ab)) do op
        measure(op, reg, locs; kwargs...)
    end
end

function measure(op::PutBlock{N}, reg::AbstractRegister, locs; kwargs...) where {N}
    _check_msize(op, reg, locs)

    # get eigen basis
    E, V = eigenbasis(op)
    ai = AddressInfo(nactive(reg), locs)
    _E = map_address(E, ai)
    _V = map_address(V, ai)
    _reg = copy(reg) |> _V'

    # perform equivalent measure
    E = diag(mat(content(_E)))
    res = measure(ComputationalBasis(), _reg, _E.locs; kwargs...)
    map(ri -> E[Int64(ri)+1], res)
end

function measure(op::PutBlock{N}, reg::AbstractRegister, locs::AllLocs; kwargs...) where {N}
    invoke(measure, Tuple{PutBlock,AbstractRegister,Any}, op, reg, locs; kwargs...)
end
