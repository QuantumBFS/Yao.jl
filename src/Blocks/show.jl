# This part is copied and tweaked from Keno/AbstractTrees.jl

struct BlockTreeCharSet
    mid
    terminator
    skip
    dash
end

# Default Charset
BlockTreeCharSet() = BlockTreeCharSet('├','└','│','─')

function print_children(io::IO, c::ChainBlock, index)
    if isassigned(c.blocks, i)
        print(io, c.blocks[index])
    else
        print(io, "#undef")
    end
end

function print_node(io::IO, c::ChainBlock{N, T}) where N where T
    print(io, "ChainBlock{", N, ", ", T, "}")
end

isparent(c::CompositeBlock) = true
isparent(c::AbstractBlock) = false

function print_tree(io::IO, entry::ChainBlock, charset, depth)
    print_node(io, entry)

    for each in entry.blocks
        print_prefix(io, charset, depth)
        print_tree(io, each)
    end
end
