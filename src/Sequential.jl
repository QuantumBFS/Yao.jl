export Sequential

"""
    Sequential <: AbstractBlock

sequencial structure that looser than a chain, it does not require qubit consistency and does not have `mat` method.
"""
struct Sequential <: AbstractBlock
    blocks::Vector{AbstractBlock}
end

Sequential(blocks::AbstractBlock...) = Sequential(collect(blocks))

Base.copy(c::Sequential) = Sequential(copy(c.blocks))
Base.similar(c::Sequential) = Sequential(empty!(similar(c.blocks)))
subblocks(c::Sequential) = c.blocks
addrs(c::Sequential) = ones(Int, subblocks(c)|>length)
chsubblocks(pb::Sequential, blks) = Sequential(blks...)

@forward Sequential.blocks Base.getindex, Base.lastindex, Base.setindex!, Base.iterate, Base.length,
    Base.eltype, Base.eachindex, Base.pop!, Base.popfirst!

# Additional Methods for Chain
Base.push!(c::Sequential, val::AbstractBlock) = (push!(c.blocks, val); c)
Base.insert!(c::Sequential, i::Integer, val::AbstractBlock) = (insert!(c.blocks, i, val); c)
Base.append!(c::Sequential, list) = (append!(c.blocks, list); c)
Base.prepend!(c::Sequential, list) = (prepend!(c.blocks, list); c)
Base.getindex(c::Sequential, index::Union{UnitRange, Vector}) = Sequential(getindex(c.blocks, index))

function apply!(r::AbstractRegister, c::Sequential)
    for each in c.blocks
        apply!(r, each)
    end
    r
end

function Base.hash(c::Sequential, h::UInt)
    hashkey = hash(objectid(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function Base.:(==)(lhs::Sequential, rhs::Sequential)
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::Sequential)
    printstyled(io, "Sequence"; bold=true, color=color(Sequential))
end

function print_subblocks(io::IO, tree::Sequential, depth, charset, active_levels)
    c = subblocks(tree)
    it_result = iterate(c)
    while it_result !== nothing
        child, st = it_result
        child_active_levels = active_levels
        print_prefix(io, depth, charset, active_levels)

        it_result = iterate(tree, st)
        if it_result === nothing
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
