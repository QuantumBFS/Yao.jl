using YaoBlocks
export LabelBlock

"""
    LabelBlock{BT,D} <: TagBlock{BT,D}

A marker to mark a circuit applying on a continous block for better plotting.
"""
struct LabelBlock{BT<:AbstractBlock,D} <: TagBlock{BT,D}
    content::BT
    name::String
end

YaoBlocks.content(cb::LabelBlock) = cb.content
function LabelBlock(x::BT, name::String) where {D,BT<:AbstractBlock{D}}
    LabelBlock{BT,D}(x, name)
end

function is_continuous_chunk(x)
    length(x) == 0 && return true
    return length(x) == maximum(x)-minimum(x)+1
end

YaoBlocks.PropertyTrait(::LabelBlock) = YaoBlocks.PreserveAll()
YaoBlocks.mat(::Type{T}, blk::LabelBlock) where {T} = mat(T, content(blk))
YaoBlocks.unsafe_apply!(reg::YaoBlocks.AbstractRegister, blk::LabelBlock) = YaoBlocks.unsafe_apply!(reg, content(blk))
YaoBlocks.chsubblocks(blk::LabelBlock, target::AbstractBlock) = LabelBlock(target, blk.name)

Base.adjoint(x::LabelBlock) = LabelBlock(adjoint(content(x)), endswith(x.name, "†") ? x.name[1:end-1] : x.name*"†")
Base.copy(x::LabelBlock) = LabelBlock(copy(content(x)), x.name)
YaoBlocks.Optimise.to_basictypes(block::LabelBlock) = block

export addlabel
addlabel(b::AbstractBlock, str::String) = LabelBlock(b, str)

# to fix issue 
function YaoBlocks.print_tree(
   io::IO,
   root::AbstractBlock,
   node::LabelBlock,
   depth::Int = 1,
   islast::Bool = false,
   active_levels = ();
   maxdepth = 5,
   charset = YaoBlocks.BlockTreeCharSet(),
   title = true,
   compact = false,
)
   print(io, node.name)
end
