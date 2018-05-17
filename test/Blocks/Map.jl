"""
    Map{N, M, T, BT} <: CompositeBlock{N, T}

map a block type to all lines.
"""
struct Map{N, M, T, BT} <: CompositeBlock{N, T}
    blocks::Tuple{M, BT}
end

function Map(n, block::MatrixBlock{N, T}) where {N, T}
    M = n ÷ N
    @assert M == 0 "cannot map this block to all lines"

    Map{n, M, T, typeof(block)}(ntuple(x->copy(block), Val{M}))
end

function copy(m::Map{N, M, T, BT}) where {N, M, T, BT}
    Map{N, M, T, BT}(ntuple(x->copy(m.blocks[x]), Val{M}))
end

getindex(m::Map, i) = getindex(m.blocks. i)
start(m::Map) = start(m.blocks)
next(m::Map, st) = next(m.blocks, st)
done(m::Map, st) = done(m.blocks, st)
eltype(m::Map) = eltype(m.blocks)
length(m::Map) = length(m.blocks)

isunitary(m::Map) = all(isunitary, m.blocks)

function sparse(m::Map{N, M}) where {N, M}
    op = sparse(first(m.blocks))
    for i=2:M
        op = kron(op, m.blocks[i])
    end

    return op
end

function dispatch!(m::Map{N, M}, params::NTuple{M, T}) where {N, M, T}
    for (block, param) in zip(m.blocks, params)
        dispatch!(block, param)
    end
    m
end
