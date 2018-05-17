"""
    Roller{N, M, T, BT} <: CompositeBlock{N, T}

map a block type to all lines and use a rolling
method to evaluate them.
"""
struct Roller{N, M, T, BT} <: CompositeBlock{N, T}
    blocks::NTuple{M, BT}
end

function Roller(n, block::MatrixBlock{N, T}) where {N, T}
    M = Int(n / N) # this will cause inexact error
    Roller{n, M, T, typeof(block)}(ntuple(x->copy(block), Val{M}))
end

function copy(m::Roller{N, M, T, BT}) where {N, M, T, BT}
    Roller{N, M, T, BT}(ntuple(x->copy(m.blocks[x]), Val{M}))
end

getindex(m::Roller, i) = getindex(m.blocks. i)
start(m::Roller) = start(m.blocks)
next(m::Roller, st) = next(m.blocks, st)
done(m::Roller, st) = done(m.blocks, st)
eltype(m::Roller) = eltype(m.blocks)
length(m::Roller) = length(m.blocks)

isunitary(m::Roller) = all(isunitary, m.blocks)

function sparse(m::Roller{N, M}) where {N, M}
    op = sparse(first(m.blocks))
    for i=2:M
        op = kron(op, m.blocks[i])
    end

    return op
end

function dispatch!(m::Roller{N, M}, params::NTuple{M, T}) where {N, M, T}
    for (block, param) in zip(m.blocks, params)
        dispatch!(block, param)
    end
    m
end

function dispatch!(m::Roller, params::Vector)
    for each in m.blocks
        dispatch!(each, params)
    end
    m
end

function apply!(reg::Register{B}, m::Roller{N, M}) where {B, N, M}
    K = N ÷ M
    st = reshape(reg.state, 1<<K, (1<<(N - 1)) * Int(B))

    for i = 1:M
        st .= sparse(m.blocks[i]) * st
        # directly use this to register
        # is dangerous, be careful, you have
        # to finish exactly M times, or the
        # address of each qubit will not match
        # the value of state
        rolldims!(Val{K}, Val{N}, Val{B}, reg.state)
    end
    reg
end

function show(io::IO, m::Roller{N, M, BT, T}) where {N, M, BT, T}
    print(io, "map $BT to $N lines ($M blocks in total)")
end
