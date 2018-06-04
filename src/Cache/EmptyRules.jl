import Base: empty!

function empty!(x::Symbol)
    # TODO: empty cache pool recursively
    x == :all && empty!(GLOBAL_CACHE_POOL)
end

"""
    empty!(type)

clear all cache in this `type`.
"""
empty!(::Type{CT}) where CT = empty!(global_cache(CT))

# """
#     empty!(::MatrixBlock, signal; recursive=false)

# do nothing if this is a matrix block.
# """
# empty!(c::MatrixBlock, signal::Int=1; recursive=false) = c

"""
    empty!(object, signal; recursive=false)

clear this object's cache with signal, if signal < level, then
do nothing.
"""
function empty!(c::Cached, signal::Int; recursive=false)
    empty!(c, cache_type(c), unsigned(signal), recursive)
end

# force empty
"""
    empty!(object; recursive=false)

force clear this object's cache
"""
function empty!(c::Cached; recursive=false)
    empty!(c, cache_type(c), recursive)
end

#################
# Implementation
#################

function empty!(c::Cached, ::Type{CT}, recursive::Bool) where CT
    if iscached(global_cache(CT), c)
        empty!(global_cache(CT), c.block)
    end
    c
end

function empty!(c::Cached{BT}, ::Type{CT}, recursive::Bool) where {CT, BT <: CompositeBlock}
    if iscacheable(global_cache(CT), c.block)
        empty!(global_cache(CT), c.block)
        if recursive
            for i in eachindex(c.block)
                empty!(c.block[i], recursive=true)
            end
        end
    end
    c
end

function empty!(c::Cached, ::Type{CT}, signal::UInt, recursive::Bool) where CT
    if iscacheable(global_cache(CT), c.block, signal)
        empty!(c, CT, recursive)
    end
    c
end

function empty!(c::Cached{BT}, ::Type{CT}, signal::UInt, recursive::Bool) where {CT, BT <: CompositeBlock}
    if iscacheable(global_cache(CT), c.block, signal)
        empty!(global_cache(CT), c.block)

        if recursive
            for i in eachindex(c.block)
                empty!(c.block[i], recursive=true)
            end
        end
    end
    c
end
