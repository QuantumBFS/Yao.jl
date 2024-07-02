"""
    LabelBlock{BT,D} <: TagBlock{BT,D}

A marker to mark a circuit applying on a continous block for better plotting.
"""
struct LabelBlock{BT<:AbstractBlock,D} <: TagBlock{BT,D}
    content::BT
    name::String
    color::String
end

YaoBlocks.content(cb::LabelBlock) = cb.content
function LabelBlock(x::BT, name::String, color::String) where {D,BT<:AbstractBlock{D}}
    LabelBlock{BT,D}(x, name, color)
end

function is_continuous_chunk(x)
    length(x) == 0 && return true
    return length(x) == maximum(x)-minimum(x)+1
end

YaoBlocks.PropertyTrait(::LabelBlock) = YaoBlocks.PreserveAll()
YaoBlocks.mat(::Type{T}, blk::LabelBlock) where {T} = mat(T, content(blk))
YaoBlocks.unsafe_apply!(reg::YaoBlocks.AbstractRegister, blk::LabelBlock) = YaoBlocks.unsafe_apply!(reg, content(blk))
YaoBlocks.chsubblocks(blk::LabelBlock, target::AbstractBlock) = LabelBlock(target, blk.name, blk.color)

Base.adjoint(x::LabelBlock) = LabelBlock(adjoint(content(x)), endswith(x.name, "†") ? x.name[1:end-1] : x.name*"†", x.color)
Base.copy(x::LabelBlock) = LabelBlock(copy(content(x)), x.name, x.color)
YaoBlocks.Optimise.to_basictypes(block::LabelBlock) = block

addlabel(b::AbstractBlock; name=string(b), color="transparent") = LabelBlock(b, name, color)

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

"""
    LineAnnotation{D} <: TrivialGate{D}
"""
struct LineAnnotation{D} <: TrivialGate{D}
    name::String
    color::String
end
line_annotation(name::String; color="black", nlevel=2) = LineAnnotation{nlevel}(name, color)

Base.copy(x::LineAnnotation) = LineAnnotation(x.name, x.color)
YaoBlocks.Optimise.to_basictypes(block::LineAnnotation) = block
YaoBlocks.nqudits(::LineAnnotation) = 1
YaoBlocks.print_block(io::IO, blk::LineAnnotation) = YaoBlocks.printstyled(io, blk.name; color=Symbol(blk.color))