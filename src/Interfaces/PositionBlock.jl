struct BlockWithPosition{BT <: AbstractBlock, PT}
    block::BT
    range::PT
end

import Base: range
range(x::BlockWithPosition) = x.range


struct DynamicSized{T}
    arg::T
end

(x::DynamicSized{BlockWithPosition{BT}})(n) where {BT <: ConstantGate} = kron(n, i=>x.arg.block for i in range(x.arg))
