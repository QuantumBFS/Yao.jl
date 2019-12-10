import YaoBase: measure!, measure
using LinearAlgebra: eigen!

"""
    eigenbasis(op::AbstractBlock{N})

Return the `eigenvalue` and `eigenvectors` of target operator.
By applying `eigenvector`' to target state,
one can swith the basis to the eigenbasis of this operator.
However, `eigenvalues` does not have a specific form.
"""
function eigenbasis(op::AbstractBlock{N}) where N
    m = mat(op)
    if m isa Diagonal || m isa IMatrix
        op, IdentityGate{N}()
    else
        E, V = eigen!(Matrix(m))
        matblock(Diagonal(E)), matblock(V)
    end
end

for GT in [:PutBlock, :RepeatedBlock, :ControlBlock,
        :Daggered]
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

function eigenbasis(op::KronBlock{N}) where N
    E = []
    blks = []
    for (k,b) in op
        Ei, Vi = eigenbasis(b)
        push!(E, k=>Ei)
        push!(blks, k=>Vi)
    end
    kron(N, E...), kron(N, blks...)
end

function eigenbasis(op::XGate)
    Z, H
end

function eigenbasis(op::YGate)
    Z, ConstGate.S*H
end

function measure!(postprocess::PostProcess, op::AbstractBlock,
        reg::AbstractRegister, locs::AllLocs; kwargs...)
    _check_msize(op, reg, locs)
    E, V = eigenbasis(op)
    res = measure!(postprocess, ComputationalBasis(), reg |> V', locs; kwargs...)
    res2 = measure!(postprocess, ComputationalBasis(), reg, locs; kwargs...)
    postprocess isa NoPostProcess && apply!(reg, V)
    diag(mat(E))[Int64.(res) .+ 1]
end

function measure(op::AbstractBlock, reg::AbstractRegister, locs::AllLocs; kwargs...)
    _check_msize(op, reg, locs)
    E, V = eigenbasis(op)
    res = measure(ComputationalBasis(), copy(reg) |> V', locs; kwargs...)
    diag(mat(E))[Int64.(res) .+ 1]
end

render_mlocs(alllocs::AllLocs, locs) = locs
render_mlocs(alllocs, locs) = alllocs[locs]

function _check_msize(op, reg, locs)
    if (locs isa AllLocs ? nactive(reg) : length(locs)) != nqubits(op)
        throw(QubitMismatchError("operator of size $(nqubits(op)) does not match register size $(nactive(reg))"))
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

function measure(op::PutBlock{N}, reg::AbstractRegister, locs; kwargs...) where N
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
    map(ri->E[Int64(ri) + 1], res)
end

function measure(op::PutBlock{N}, reg::AbstractRegister, locs::AllLocs; kwargs...) where N
    invoke(measure, Tuple{PutBlock, AbstractRegister, Any}, op, reg, locs; kwargs...)
end
