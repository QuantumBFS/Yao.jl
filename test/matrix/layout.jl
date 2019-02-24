using YaoBlockTree

struct BlockTreeCharSet
    mid
    terminator
    skip
    dash
end

# Default Charset
BlockTreeCharSet() = BlockTreeCharSet('├','└','│','─')

title(io::IO, x::AbstractBlock) = summary(io, x)
# color(::Type{T}) where {T <: PauliString} = :cyan
# color(::Type{T}) where {T <: RepeatedBlock} = :cyan
# color(::Type{T}) where {T <: Swap} = :magenta
# color(::Type{T}) where {T <: Sequential} = :blue
# color(::Type{T}) where {T <: PutBlock} = :cyan
# color(::Type{T}) where {T <: Roller} = :cyan



_charwidth(c::Char) = textwidth(c)
_charwidth(s) = sum(map(textwidth, collect(s)))

function print_tree(
    io::IO,
    root::AbstractBlock,
    node::AbstractBlock,
    depth=1,
    active_levels=Int[];
    maxdepth=5, charset=BlockTreeCharSet(), title=true)

    if root === node && title
        title(io, root)
    end

    push!(active_levels, depth)
    print_block(io, node)

    for (k, each_node) in enumerate(subblocks(node))
        if k == lastindex(subblocks)
            print(io, " "^indent, charset.terminator)
            print_tree(io, root, each_node, active_levels)
        else
            print(io, " "^indent, charset.mid)
            print_tree(io, root, each_node, active_levels)
        end
    end

    return nothing
end

print_node(io::IO, )
