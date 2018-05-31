"""
    Roller{N, M, T, BT} <: CompositeBlock{N, T}

map a block type to all lines and use a rolling
method to evaluate them.

## TODO

fill identity like `KronBlock`
"""
struct Roller{N, M, T, BT <: Tuple} <: CompositeBlock{N, T}
    blocks::BT

    function Roller{N, T}(blocks::Tuple) where {N, T}
        M = length(blocks)
        new{N, M, T, typeof(blocks)}(blocks)
    end

    function Roller{N, T}(blocks::MatrixBlock...) where {N, T}
        Roller{N, T}(blocks)
    end

    function Roller{N}(block::MatrixBlock{K, T}) where {N, K, T}
        M = Int(N / K)
        new{N, M, T, NTuple{M, typeof(block)}}(ntuple(x->deepcopy(block), Val(M)))
    end
end

function copy(m::Roller{N, M, T, BT}) where {N, M, T, BT}
    Roller{N, T}(ntuple(x->copy(m.blocks[x]), Val(M)))
end

getindex(m::Roller, i) = getindex(m.blocks, i)
start(m::Roller) = start(m.blocks)
next(m::Roller, st) = next(m.blocks, st)
done(m::Roller, st) = done(m.blocks, st)
eltype(m::Roller) = eltype(m.blocks)
length(m::Roller) = length(m.blocks)
eachindex(m::Roller) = eachindex(m.blocks)
blocks(m::Roller) = m.blocks

isunitary(m::Roller) = all(isunitary, m.blocks)

function mat(m::Roller{N, M}) where {N, M}
    op = mat(first(m.blocks))
    for i=2:M
        op = kron(mat(m.blocks[i]), op)
    end

    return op
end

function apply!(reg::Register{B}, m::Roller{N, M}) where {B, N, M}
    K = N ÷ M
    st = reshape(reg.state, 1<<K, (1<<(N - 1)) * B)

    for i = 1:M
        st .= mat(m.blocks[i]) * st
        # directly use this to register
        # is dangerous, be careful, you have
        # to finish exactly M times, or the
        # address of each qubit will not match
        # the value of state
        rolldims!(Val(K), Val(N), Val(B), statevec(reg))
    end
    reg
end


