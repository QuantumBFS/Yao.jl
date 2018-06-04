export RangedBlock

"""
    RangedBlock

A block with a range of its position. This is a duck typed block.
It is not part of the block system. It is used to support auto-inferred
position, etc.
"""
struct RangedBlock{BT, RT}
    block::BT
    range::RT
end

import Base: show

function show(io::IO, x::RangedBlock{BT, Int}) where BT
    print(io, x.block, " at line ", x.range)
end

function show(io::IO, x::RangedBlock)
    print(io, x.block, " in line range ", x.range)
end
