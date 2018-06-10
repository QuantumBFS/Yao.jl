# Pretty Printing

function show(io::IO, c::AbstractBlock)
    print_tree(io, c)
end

# This part is copied and tweaked from Keno/AbstractTrees.jl

struct BlockTreeCharSet
    mid
    terminator
    skip
    dash
end

# Color Traits
color(::Type{T}) where {T <: Roller} = :cyan
color(::Type{T}) where {T <: KronBlock} = :cyan
color(::Type{T}) where {T <: RepeatedBlock} = :cyan
color(::Type{T}) where {T <: ChainBlock} = :blue
color(::Type{T}) where {T <: ControlBlock} = :red
color(::Type{T}) where {T <: Swap} = :magenta

# Default Charset
BlockTreeCharSet() = BlockTreeCharSet('├','└','│','─')

_charwidth(c::Char) = charwidth(c)
_charwidth(s) = sum(map(charwidth, collect(s)))

function print_prefix(io, depth, charset, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io, charset.skip, " "^(_charwidth(charset.dash) + 1))
        else
            print(io, " "^(_charwidth(charset.skip) + _charwidth(charset.dash) + 1))
        end
    end
end

blocks(x::PrimitiveBlock) = ()

print_tree(io::IO, tree::PrimitiveBlock, maxdepth=5) = print_block(io, tree)
print_tree(io::IO, tree::CachedBlock{ST, BT}, maxdepth=5) where {ST, BT <: PrimitiveBlock} = print_block(io, tree)

function print_tree(
    io::IO, tree, maxdepth = 5;
    line=nothing,
    depth=0,
    active_levels=Int[],
    charset=BlockTreeCharSet(),
    roottree=tree,
    title=true,
)
    nodebuf = IOBuffer()
    isa(io, IOContext) && (nodebuf = IOContext(nodebuf, io))

    # print circuit summary
    if (tree === roottree) && title
        println(io, "Total: ", nqubits(tree), ", DataType: ", datatype(tree))
    end

    if line !== nothing
        printstyled(io, line; bold=true, color=:white)
        print(io, "=>")
    end
    print_block(nodebuf, tree)

    str = String(take!(isa(nodebuf, IOContext) ? nodebuf.io : nodebuf))

    lines = split(str, '\n')
    for (i, line) in enumerate(lines)
        i != 1 && print_prefix(io, depth, charset, active_levels)
        println(io, line)
    end

    print_subblocks(io, tree, depth, charset, active_levels)
end

print_tree(tree, args...; kwargs...) = print_tree(STDOUT::IO, tree, args...; kwargs...)

print_subblocks(io::IO, tree, depth, charset, active_levels) = nothing

function print_subblocks(io::IO, tree::CompositeBlock, depth, charset, active_levels)
    c = blocks(tree)
    st = start(c)
    while !done(c, st)
        child, st = next(c, st)
        child_active_levels = active_levels
        print_prefix(io, depth, charset, active_levels)
        if done(c, st)
            print(io, charset.terminator)
        else
            print(io, charset.mid)
            child_active_levels = push!(copy(active_levels), depth)
        end

        print(io, charset.dash, ' ')
        print_tree(
            io, child;
            depth=depth+1,
            active_levels=child_active_levels,
            charset=charset,
            roottree=tree,
        )
    end
end

function print_subblocks(io::IO, tree::KronBlock, depth, charset, active_levels)
    st = start(tree)
    while !done(tree, st)
        (line, child), st = next(tree, st)
        child_active_levels = active_levels
        print_prefix(io, depth, charset, active_levels)
        if done(tree, st)
            print(io, charset.terminator)
        else
            print(io, charset.mid)
            child_active_levels = push!(copy(active_levels), depth)
        end

        print(io, charset.dash, ' ')
        print_tree(
            io, child;
            line=line,
            depth=depth+1,
            active_levels=child_active_levels,
            charset=charset,
            roottree=tree,
        )
    end
end

function print_subblocks(io::IO, tree::ControlBlock, depth, charset, active_levels)
    print_prefix(io, depth, charset, active_levels)
    print(io, charset.terminator)
    print(io, charset.dash, ' ')
    print_tree(
        io, tree.block;
        line=tree.addr,
        depth=depth+1,
        active_levels=active_levels,
        charset=charset,
        roottree=tree,
    )
end

function print_block(io::IO, x::PrimitiveBlock)

    @static if VERSION < v"0.7-"
        print(io, summary(x))
    else
        summary(io, x)
    end

end

# FIXME: make this works in v0.7
function print_block(io::IO, x::CompositeBlock)

    @static if VERSION < v"0.7-"
        print(io, summary(x))
    else
        summary(io, x)
    end

end

function print_block(io::IO, x::ChainBlock)
    printstyled(io, "chain"; bold=true, color=color(ChainBlock))
end

function print_block(io::IO, x::KronBlock)
    printstyled(io, "kron"; bold=true, color=color(KronBlock))
end

function print_block(io::IO, x::Roller)
    printstyled(io, "roller"; bold=true, color=color(Roller))
end

function print_block(io::IO, x::ControlBlock)
    printstyled(io, "control("; bold=true, color=color(ControlBlock))

    for i in eachindex(x.ctrl_qubits)
        printstyled(io, x.ctrl_qubits[i]; bold=true, color=color(ControlBlock))

        if i != lastindex(x.ctrl_qubits)
            printstyled(io, ", "; bold=true, color=color(ControlBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(ControlBlock))
end

function print_block(io::IO, R::RotationGate)
    print(io, "Rot ", R.U, ": ", R.theta)
end
