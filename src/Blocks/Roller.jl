export Roller

"""
    Roller{N, T, BT} <: CompositeBlock{N, T}

map a block type to all lines and use a rolling
method to evaluate them.

## TODO

fill identity like `KronBlock` -> To interface.
"""
struct Roller{N, T, BT <: Tuple} <: CompositeBlock{N, T}
    blocks::BT
    function Roller{N, T, BT}(blocks::BT) where {N, T, BT}
        sum(nqubits, blocks) == N || throw(AddressConflictError("Size of blocks does not match roller size."))
        new{N, T, BT}(blocks)
    end
end

Roller{T}(blocks::Tuple) where T = Roller{sum(nqubits, blocks), T, typeof(blocks)}(blocks)
Roller(blocks::Tuple) = Roller{blocks|>_blockpromote}(blocks)
Roller(blocks::AbstractBlock...) = Roller(blocks)

function Roller{N}(block::MatrixBlock{K, T}) where {N, K, T}
    Roller{N, T, NTuple{N÷K, typeof(block)}}(ntuple(x->deepcopy(block), Val(N÷K)))
end

copy(m::Roller) = typeof(m)(m.blocks)

subblocks(m::Roller) = m.blocks
addrs(m::Roller) = cumsum([[1]; [nqubits(b) for b in m.blocks[1:end-1]]])
isunitary(m::Roller) = all(isunitary, m.blocks) || isunitary(mat(m))
ishermitian(m::Roller) = all(ishermitian, m.blocks) || ishermitian(mat(m))
isreflexive(m::Roller) = all(isreflexive, m.blocks) || isreflexive(mat(m))
chsubblocks(pb::Roller, blocks) where N = Roller((blocks...,))

⊗ = kron
mat(m::Roller) = mapreduce(blk->mat(blk), ⊗, m.blocks[end:-1:1])
adjoint(blk::Roller) = Roller(map(adjoint, blk.blocks))

function apply!(reg::AbstractRegister{B}, m::Roller{N}) where {B, N}
    st = reg.state
    for block in m.blocks
        K = nqubits(block)
        st[:] = vec(mat(block) * reshape(st, 1<<K, :))
        rolldims!(Val(K), Val(N), Val(B), statevec(reg))
    end
    reg
end

==(lhs::Roller{N, T, BT}, rhs::Roller{N, T, BT}) where {N, T, BT} = lhs.blocks == rhs.blocks

function hash(R::Roller, h::UInt)
    hashkey = hash(objectid(R), h)
    for each in R.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function cache_key(R::Roller)
    ntuple(k->cache_key(R.blocks[k]), Val(R.blocks |> length))
end

function print_block(io::IO, x::Roller)
    printstyled(io, "roller"; bold=true, color=color(Roller))
end
