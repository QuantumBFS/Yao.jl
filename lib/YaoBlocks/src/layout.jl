export print_tree, print_annotation, print_prefix, print_title, print_block

struct BlockTreeCharSet
    mid::Any
    terminator::Any
    skip::Any
    dash::Any
end

# Default Charset
BlockTreeCharSet() = BlockTreeCharSet('├', '└', '│', '─')

_charwidth(c::Char) = textwidth(c)
_charwidth(s) = sum(map(textwidth, collect(s)))

"""
    print_prefix(io, depth, charset, active_levels)

print prefix of a tree node in a single line.
"""
function print_prefix(io::IO, depth, charset, active_levels)
    for current_depth = 2:depth
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
function print_title(io::IO, x::AbstractBlock)
    printstyled(io, "nqudits: ", nqudits(x); bold = false, color = :cyan)
end

function print_title(io::IO, x::AbstractBlock{2})
    printstyled(io, "nqubits: ", nqudits(x); bold = false, color = :cyan)
end

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
print_tree(root; kwargs...) = print_tree(stdout, root; kwargs...)

Base.show(io::IO, blk::AbstractBlock) = show(io, "plain/text", blk)
Base.show(io::IO, ::MIME"plain/text", blk::AbstractBlock) = print_tree(io, blk)


function Base.show(io::IO, ::MIME"plain/text", blk::TagBlock{<:PrimitiveBlock})
    return print_tree(io, blk; title = false, compact = false)
end

Base.show(io::IO, ::MIME"plain/text", blk::PrimitiveBlock) =
    print_tree(io, blk; title = false, compact = true)

print_tree(io::IO, root::AbstractBlock; kwargs...) = print_tree(io, root, root; kwargs...)

"""
    print_tree(io, root, node[, depth=1, active_levels=()]; kwargs...)

Print the block tree.

# Keywords

- `maxdepth`: max tree depth to print
- `charset`: default is ('├','└','│','─'). See also `YaoBlocks.BlockTreeCharSet`.
- `title`: control whether to print the title, `true` or `false`, default is `true`
"""
function print_tree(
    io::IO,
    root::AbstractBlock,
    node::AbstractBlock,
    depth::Int = 1,
    islast::Bool = false,
    active_levels = ();
    maxdepth = 5,
    charset = BlockTreeCharSet(),
    title = true,
    compact = false,
)

    if root === node && title
        print_title(io, root)
        println(io)
    end

    if root === node
        islast = true
    end

    print_block(io, node)
    _println(io, node, islast, compact)

    kwargs = (maxdepth = maxdepth, charset = charset, title = false, compact = compact)
    for (k, each_node) in enumerate(subblocks(node))
        if k == lastindex(subblocks(node))
            print_prefix(io, depth, charset, active_levels)
            print(io, charset.terminator, charset.dash)
            print(io, " ")
            print_annotation(io, root, node, each_node, k)
            print_tree(
                io,
                root,
                each_node,
                depth + 1,
                islast && isempty(subblocks(each_node)),
                active_levels;
                kwargs...,
            )
        else
            print_prefix(io, depth, charset, active_levels)
            print(io, charset.mid, charset.dash)
            print(io, " ")
            print_annotation(io, root, node, each_node, k)
            print_tree(
                io,
                root,
                each_node,
                depth + 1,
                false,
                (active_levels..., depth + 1);
                kwargs...,
            )
        end
    end

    return nothing
end

function print_tree(
    io::IO,
    root::AbstractBlock,
    node::TagBlock,
    depth::Int = 1,
    islast::Bool = false,
    active_levels = ();
    maxdepth = 5,
    charset = BlockTreeCharSet(),
    title = true,
    compact = false,
)

    if root === node && title
        print_title(io, root)
        println(io)
    end

    if root === node
        print_annotation(io, root, root, root, 1)
        islast = true
    end

    kwargs = (maxdepth = maxdepth, charset = charset, title = false, compact = compact)
    child = content(node)
    print_annotation(io, root, node, child, 1)
    print_tree(
        io,
        root,
        child,
        depth + 1,
        islast && isempty(subblocks(child)),
        active_levels;
        kwargs...,
    )

    return nothing
end

_println(io::IO, node::AbstractBlock, islast, compact) = !compact && println(io)
function _println(io::IO, node::Union{TagBlock,PrimitiveBlock}, islast, compact)
    if !compact && !islast
        println(io)
    end
end

# Custom layouts
color(m::AbstractBlock) = color(typeof(m))
color(::Type{<:ControlBlock}) = :red
color(::Type{<:ChainBlock}) = :blue
color(::Type{<:Add}) = :red
color(::Type{<:PutBlock}) = :cyan
color(::Type{<:RepeatedBlock}) = :cyan
color(::Type{<:GeneralMatrixBlock}) = :red

print_block(io::IO, g::PhaseGate) = print(io, "phase(", g.theta, ")")
print_block(io::IO, S::ShiftGate) = print(io, "shift(", S.theta, ")")
print_block(io::IO, R::RotationGate) = print(io, "rot(", content(R), ", ", R.theta, ")")
print_block(io::IO, x::KronBlock) =
    printstyled(io, "kron"; bold = true, color = color(KronBlock))
print_block(io::IO, x::ChainBlock) =
    printstyled(io, "chain"; bold = true, color = color(ChainBlock))
print_block(io::IO, x::UnitaryChannel) = printstyled(io, "unitary_channel"; bold = true)
print_block(io::IO, c::Subroutine) = print(io, "Subroutine: ", occupied_locs(c))
print_block(io::IO, c::CachedBlock) = print_block(io, content(c))
print_block(io::IO, c::Add) = printstyled(io, "+"; bold = true, color = color(Add))
print_block(io::IO, c::TagBlock) = nothing
print_block(io::IO, c::GeneralMatrixBlock) =
    printstyled(io, c.tag; color = color(GeneralMatrixBlock))

function print_block(io::IO, c::Measure{D,K,OT}) where {D,K,OT}
    strs = String[]
    if c.operator != ComputationalBasis()
        push!(strs, "operator=$(repr(c.operator))")
    end

    if c.locations != AllLocs()
        push!(strs, "locs=$(repr(c.locations))")
    end

    if !(c.postprocess isa NoPostProcess)
        push!(strs, "postprocess=$(c.postprocess)")
    end

    out = join(strs, ", ")
    if !isempty(strs)
        out = "Measure($(nqudits(c));" * out
    else
        out = "Measure($(nqudits(c))" * out
    end

    return print(io, out, ")")
end

# TODO: use OhMyREPL's default syntax highlighting for functions
function print_block(io::IO, te::TimeEvolution)
    println(io, "Time Evolution Δt = $(te.dt), tol = $(te.tol)")
    print_tree(io, te.H; title = false)
end

function print_block(io::IO, x::ControlBlock)
    printstyled(io, "control("; bold = true, color = color(ControlBlock))

    for i in eachindex(x.ctrl_locs)
        x.ctrl_config[i] == 0 &&
            printstyled(io, '¬'; bold = true, color = color(ControlBlock))
        printstyled(io, x.ctrl_locs[i]; bold = true, color = color(ControlBlock))

        if i != lastindex(x.ctrl_locs)
            printstyled(io, ", "; bold = true, color = color(ControlBlock))
        end
    end
    printstyled(io, ")"; bold = true, color = color(ControlBlock))
end

function print_block(io::IO, pb::PutBlock)
    printstyled(io, "put on ("; bold = true, color = color(PutBlock))
    for i in eachindex(pb.locs)
        printstyled(io, pb.locs[i]; bold = true, color = color(PutBlock))
        if i != lastindex(pb.locs)
            printstyled(io, ", "; bold = true, color = color(PutBlock))
        end
    end
    printstyled(io, ")"; bold = true, color = color(PutBlock))
end

function print_block(io::IO, rb::RepeatedBlock)
    printstyled(io, "repeat on ("; bold = true, color = color(RepeatedBlock))
    for i in eachindex(rb.locs)
        printstyled(io, rb.locs[i]; bold = true, color = color(RepeatedBlock))
        if i != lastindex(rb.locs)
            printstyled(io, ", "; bold = true, color = color(RepeatedBlock))
        end
    end
    printstyled(io, ")"; bold = true, color = color(RepeatedBlock))
end

# forward to simplify interfaces
function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::AbstractBlock,
    child::AbstractBlock,
    k = 1,
)
    print_annotation(io, child)
end

print_annotation(io::IO, node::AbstractBlock) = nothing # skip
print_annotation(io::IO, c::Daggered) =
    printstyled(io, " [†]"; bold = true, color = :yellow)
print_annotation(io::IO, c::CachedBlock) =
    printstyled(io, "[cached] "; bold = true, color = :yellow)

function print_annotation(io::IO, x::Scale)
    if x.alpha == im
        printstyled(io, "[+im] "; bold = true, color = :yellow)
    elseif x.alpha == -im
        printstyled(io, "[-im] "; bold = true, color = :yellow)
    elseif x.alpha == 1
        printstyled(io, "[+] "; bold = true, color = :yellow)
    elseif x.alpha == -1
        printstyled(io, "[-] "; bold = true, color = :yellow)
    elseif real(x.alpha) == 0
        printstyled(io, "[scale: ", imag(x.alpha), "im] "; bold = true, color = :yellow)
    else
        printstyled(io, "[scale: ", x.alpha, "] "; bold = true, color = :yellow)
    end
end

function print_annotation(io::IO, x::Scale{Val{S}}) where {S}
    print_annotation(io, Scale(S, x))
end

function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::KronBlock,
    child::AbstractBlock,
    k::Int,
)
    if length(node.locs[k]) == 1
        printstyled(io, node.locs[k].start; bold = true, color = :white)
    else
        printstyled(io, node.locs[k]; bold = true, color = :white)
    end
    print(io, "=>")
    print_annotation(io, child)
end

function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::ControlBlock,
    child::AbstractBlock,
    k::Int,
)

    printstyled(io, node.locs; bold = true, color = :white)
    print(io, " ")
    print_annotation(io, child)
end

function print_annotation(
    io::IO,
    root::AbstractBlock,
    node::UnitaryChannel,
    child::AbstractBlock,
    k::Int,
)
    print_annotation(io, child)
    printstyled(io, "[", node.probs[k], "] "; color = :cyan)
end
