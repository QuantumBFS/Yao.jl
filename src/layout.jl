export print_tree

struct BlockTreeCharSet
    mid
    terminator
    skip
    dash
end

# Default Charset
BlockTreeCharSet() = BlockTreeCharSet('├','└','│','─')

_charwidth(c::Char) = textwidth(c)
_charwidth(s) = sum(map(textwidth, collect(s)))

"""
    print_prefix(io, depth, charset, active_levels)

print prefix of a tree node in a single line.
"""
function print_prefix(io::IO, depth, charset, active_levels)
    for current_depth in 2:depth
        if current_depth in active_levels
            print(io, charset.skip, " "^(_charwidth(charset.dash) + 1))
        else
            print(io, " "^(_charwidth(charset.skip) + _charwidth(charset.dash) + 1))
        end
    end
end

"""
    print_title(io, block)

Print the title of given `block` of an [`AbstractBlock`](@ref).
"""
print_title(io::IO, x::AbstractBlock) = summary(io, x)


"""
    print_annotation(io, root, node, child, k)

Print the annotation of `k`-th `child` of node, aka the `k`-th element of
`subblocks(node)`.
"""
print_annotation(io::IO, root, node, child, k) = nothing

"""
    print_tree([io=stdout], root)

Print the block tree.
"""
print_tree(root) = print_tree(stdout, root)

Base.show(io::IO, blk::AbstractBlock) = show(io, "plain/text", blk)
Base.show(io::IO, ::MIME"plain/text", blk::AbstractBlock) = print_tree(io, blk)
Base.show(io::IO, ::MIME"plain/text", blk::PrimitiveBlock) = print_tree(io, blk; title=false, compact=true)

"""
    print_tree(io, root, node[, depth=1, active_levels=()]; kwargs...)

Print the block tree.

# Keywords

- `maxdepth`: max tree depth to print
- `charset`: default is ('├','└','│','─'). See also [`BlockTreeCharSet`](@ref).
- `title`: control whether to print the title, `true` or `false`, default is `true`
"""
function print_tree(
    io::IO,
    root::AbstractBlock,
    node::AbstractBlock = root,
    depth::Int=1,
    active_levels=();
    maxdepth=5, charset=BlockTreeCharSet(), title=true, compact=false)

    if root === node && title
        print_title(io, root)
        println(io)
    end

    print_block(io, node)
    if !compact
        println(io)
    end

    for (k, each_node) in enumerate(subblocks(node))
        if k == lastindex(subblocks(node))
            print_prefix(io, depth, charset, active_levels)
            print(io, charset.terminator, charset.dash)
            print_annotation(io, root, node, each_node, k)
            print_tree(io, root, each_node, depth+1, active_levels)
        else
            print_prefix(io, depth, charset, active_levels)
            print(io, charset.mid, charset.dash)
            print_annotation(io, root, node, each_node, k)
            print_tree(io, root, each_node, depth+1, (active_levels..., depth+1))
        end
    end

    return nothing
end


# Custom layouts
color(m::AbstractBlock) = color(typeof(m))
color(::Type{<:Swap}) = :magenta
color(::Type{<:ControlBlock}) = :red
color(::Type{<:ChainBlock}) = :blue
color(::Type{<:Roller}) = :cyan
color(::Type{<:MathGate}) = :red
color(::Type{<:PutBlock}) = :cyan
color(::Type{<:RepeatedBlock}) = :cyan

# color(::Type{T}) where {T <: PauliString} = :cyan
# color(::Type{T}) where {T <: Sequential} = :blue

print_block(io::IO, g::PhaseGate) = print(io, "phase(", g.theta, ")")
print_block(io::IO, S::ShiftGate) = print(io, "shift(", S.theta, ")")
print_block(io::IO, R::RotationGate) = print(io, "rot(", R.block, ", ", R.theta, ")")
print_block(io::IO, swap::Swap) = printstyled(io, "swap", swap.locs; bold=true, color=color(Swap))
print_block(io::IO, x::KronBlock) = printstyled(io, "kron"; bold=true, color=color(KronBlock))
print_block(io::IO, x::ChainBlock) = printstyled(io, "chain"; bold=true, color=color(ChainBlock))
print_block(io::IO, x::Roller) = printstyled(io, "roller"; bold=true, color=color(Roller))
print_block(io::IO, x::ReflectGate{N}) where N = print(io, "reflect: nqubits=$N")
print_block(io::IO, c::Concentrator) = print(io, "Concentrator: ", occupied_locations(c))
print_block(io::IO, c::CachedBlock) = print_block(io, c.block)
print_block(io::IO, c::Daggered) = print_block(io, c.block)

# TODO: use OhMyREPL's default syntax highlighting for functions
function print_block(io::IO, m::MathGate{N, <:LegibleLambda}) where N
    printstyled(io, "mathgate($(m.f); nbits=$N, bview=$(nameof(m.v)))"; bold=true, color=color(m))
end

function print_block(io::IO, m::MathGate{N, <:Function}) where N
    printstyled(io, "mathgate($(nameof(m.f)); nbits=$N, bview=$(nameof(m.v)))"; bold=true, color=color(m))
end

function print_block(io::IO, te::TimeEvolution)
    println(io, "Time Evolution Δt = $(te.dt), tol = $(te.tol)")
    print_tree(io, te.H.block; title=false)
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

function print_block(io::IO, pb::PutBlock{N}) where N
    printstyled(io, "put on ("; bold=true, color=color(PutBlock))
    for i in eachindex(pb.addrs)
        printstyled(io, pb.addrs[i]; bold=true, color=color(PutBlock))
        if i != lastindex(pb.addrs)
            printstyled(io, ", "; bold=true, color=color(PutBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(PutBlock))
end

function print_block(io::IO, rb::RepeatedBlock{N}) where N
    printstyled(io, "repeat on ("; bold=true, color=color(RepeatedBlock))
    for i in eachindex(rb.addrs)
        printstyled(io, rb.addrs[i]; bold=true, color=color(RepeatedBlock))
        if i != lastindex(rb.addrs)
            printstyled(io, ", "; bold=true, color=color(RepeatedBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(RepeatedBlock))
end

print_annotation(io::IO, c::Daggered) =
    printstyled(io, " [†]"; bold=true, color=:yellow)
print_annotation(io::IO, c::CachedBlock) =
    printstyled(io, "[↺] "; bold=true, color=:yellow)

function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::KronBlock,
    child::AbstractBlock,
    k::Int)

    printstyled(io, k; bold=true, color=:white)
    print(io, "=>")
end

function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::ControlBlock,
    child::AbstractBlock,
    k::Int)

    printstyled(io, node.addrs; bold=true, color=:white)
    print(io, "=>")
end
