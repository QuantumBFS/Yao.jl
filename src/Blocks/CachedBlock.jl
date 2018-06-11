export CachedBlock, update_cache

"""
    CachedBlock{ST, BT, N, T} <: MatrixBlock{N, T}

A label type that tags an instance of type `BT`. It forwards
every methods of the block it contains, except [`mat`](@ref)
and [`apply!`](@ref), it will cache the matrix form whenever
the program has.
"""
struct CachedBlock{ST, BT, N, T} <: MatrixBlock{N, T}
    server::ST
    block::BT
    level::Int

    function CachedBlock(server::ST, x::BT, level::Int) where {ST, N, T, BT <: MatrixBlock{N, T}}
        alloc!(server, x, CacheFragment(x))
        new{ST, BT, N, T}(server, x, level)
    end
end

iscached(c::CachedBlock) = iscached(c.server, c.block)
iscacheable(c::CachedBlock) = iscacheable(c.server, c.block)

function update_cache(c::CachedBlock)
    if !iscached(c.server, c.block)
        m = dropzeros!(mat(c.block))
        push!(c.server, m, c.block)
    end
    c
end

clear!(x::MatrixBlock) = x
clear!(c::CachedBlock) = (clear!(c.server, c.block); c)

# forward methods

function mat(c::CachedBlock)
    if !iscached(c.server, c.block)
        m = dropzeros!(mat(c.block))
        push!(c.server, m, c.block)
        return m
    end
    pull(c)
end

function pull(c::CachedBlock)
    pull(c.server, c.block)
end

function apply!(r::AbstractRegister, c::CachedBlock, signal)
    if signal > c.level
        r.state .= mat(c) * r
    else
        apply!(r, c.block)
    end
end

apply!(r::AbstractRegister, c::CachedBlock) = (r.state .= mat(c) * r; r)

similar(c::CachedBlock, level::Int) = CachedBlock(c.server, c.block, level)

#############################
# Direct Inherited Methods
#############################

dispatch!(c::CachedBlock, params...) = (dispatch!(c.block, params...); c)
getindex(c::CachedBlock, index...) = getindex(c.block, index...)
setindex!(c::CachedBlock, val, index...) = setindex!(c.block, val, index...)

start(c::CachedBlock) = start(c.block)
next(c::CachedBlock, st) = next(c.block, st)
done(c::CachedBlock, st) = done(c.block, st)
length(c::CachedBlock) = length(c.block)
eltype(c::CachedBlock) = eltype(c.block)
blocks(c::CachedBlock) = blocks(c.block)

# Print
print_subblocks(io::IO, tree::CachedBlock, depth, charset, active_levels) = print_subblocks(io, tree.block, depth, charset, active_levels)

function print_block(io::IO, c::CachedBlock)
    print(io, "(Cached)")
    print_block(io, c.block)
end
