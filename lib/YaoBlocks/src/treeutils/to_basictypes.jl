export to_basictypes

"""
    to_basictypes(block::AbstractBlock)

convert gates to basic types

    * ChainBlock
    * PutBlock
    * PrimitiveBlock
"""
function to_basictypes end

to_basictypes(block::PrimitiveBlock) = block
function to_basictypes(block::AbstractBlock)
    throw(NotImplementedError(:to_basictypes, typeof(block)))
end

function to_basictypes(block::RepeatedBlock)
    chain(block.n, map(i -> put(block.n, i => content(block)), block.locs))
end

to_basictypes(block::CachedBlock) = content(block)
function to_basictypes(block::Subroutine{D,<:PrimitiveBlock}) where {D}
    put(nqudits(block), block.locs => content(block))
end
function to_basictypes(block::Subroutine)
    to_basictypes(map_address(content(block), AddressInfo(block.n, [block.locs...])))
end
function to_basictypes(block::Subroutine{D,<:Measure}) where {D}
    map_address(content(block), AddressInfo(nqudits(block), [block.locs...]))
end
to_basictypes(block::Daggered) = Daggered(block.content)
to_basictypes(block::Scale) = Scale(block.alpha, block.content)
to_basictypes(block::KronBlock) =
    chain(block.n, [put(block.n, i => block[i]) for i in block.locs])
to_basictypes(block::Union{Add,PutBlock,ChainBlock,ControlBlock}) = block
