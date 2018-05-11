struct ChainBlock{N, T, TD <: Tuple} <: CompositeBlock{N, T}
    blocks::TD
end

_promote_chain_eltype(a) = eltype(a)
_promote_chain_eltype(a, b) = promote_type(eltype(a), eltype(b))
_promote_chain_eltype(t::Type, a, b) = promote_type(t, _promote_chain_eltype(a, b))
_promote_chain_eltype(t::Type, a, b, c...) = _promote_chain_eltype(_promote_chain_eltype(t, a, b), c...)
_promote_chain_eltype(a, b, c...) = _promote_chain_eltype(_promote_chain_eltype(a, b), c...)

function ChainBlock(n, blocks::TD) where {TD <: Tuple}
    ChainBlock{n, _promote_chain_eltype(blocks...), TD}(blocks)
end

function ChainBlock(blocks::PureBlock{N}...) where N
    ChainBlock(N, blocks)
end

function copy(c::ChainBlock{N, T, TD}) where {N, T, TD}
    blocks = ntuple(i->copy(c.blocks[i]), length(c.blocks))
    ChainBlock{N, T, TD}(blocks)
end


isunitary(block::ChainBlock) = all(isunitary, block.blocks)

# TODO: provide matrix form when there are Concentrators
# TODO: use reverse! instead?
full(c::ChainBlock) = prod(x->full(x), reverse(c.blocks))
sparse(c::ChainBlock) = prod(x->sparse(x), reverse(c.blocks))

function apply!(reg::Register, c::ChainBlock)
    for each in c.blocks
        apply!(reg, each)
    end
    reg
end

function dispatch!(c::ChainBlock, params...)
    for each in params
        index, param = each
        dispatch!(c.blocks[index], param...)
    end
    c
end

function show(io::IO, c::ChainBlock{N, T}) where {N, T}
    println(io, "ChainBlock{$N, $T}")
    join(io, ["\t" * string(each) for each in c.blocks], "\n----")
end
