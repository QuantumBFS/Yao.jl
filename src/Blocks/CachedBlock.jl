export CachedBlock, update_cache

"""
    CachedBlock{ST, BT, N, T} <: MatrixBlock{N, T}

A label type that tags an instance of type `BT`. It forwards
every methods of the block it contains, except [`mat`](@ref)
and [`apply!`](@ref), it will cache the matrix form whenever
the program has.
"""
struct CachedBlock{ST, BT, N, T} <: TagBlock{N, T}
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

parent(c::CachedBlock) = c.block
similar(c::CachedBlock, level::Int) = CachedBlock(c.server, c.block, level)
copy(c::CachedBlock, level::Int) = CachedBlock(c.server, copy(c.block), level)

function print_block(io::IO, c::CachedBlock)
    print_block(io, c.block)
    print(io, " (Cached)")
end
