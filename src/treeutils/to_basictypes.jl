export to_basictypes

"""
    to_basictypes(block::AbstractBlock{N}) where N

convert gates to basic types

    * ChainBlock
    * PutBlock
    * PrimitiveBlock
"""
function to_basictypes end

to_basictypes(block::PrimitiveBlock) = block
function to_basictypes(block::AbstractBlock{N}) where N
    throw(NotImplementedError(:to_basictypes, typeof(block)))
end

function to_basictypes(block::RepeatedBlock{N}) where N
    chain(N, map(i->put(N, i=>content(block)), block.locs))
end

to_basictypes(block::CachedBlock) = content(block)
function to_basictypes(block::Concentrator{N,<:PrimitiveBlock}) where N
    put(N, block.locs=>content(block))
end
function to_basictypes(block::Concentrator{N}) where N
    to_basictypes(map_address(content(block), AddressInfo(N, [block.locs...])))
end
function to_basictypes(block::Concentrator{N,<:Measure}) where N
    map_address(content(block), AddressInfo(N, [block.locs...]))
end
to_basictypes(block::Daggered) where N = Daggered(block.content)
to_basictypes(block::Scale) where N = Scale(block.alpha, block.content)
to_basictypes(block::KronBlock{N}) where N = chain(N, [put(N, i=>block[i]) for i=block.locs])
to_basictypes(block::Union{Add, PutBlock, ChainBlock, ControlBlock}) where N = block
