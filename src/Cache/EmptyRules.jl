import Base: empty!

function empty!(x::Symbol)
    x == :all && empty!(GLOBAL_CACHE_POOL)
end

empty!(::Type{CT}) where CT = empty!(global_cache(CT))
empty!(c::MatrixBlock, signal; recursive=false) = c

function empty!(c::Cached, signal::Int; recursive=false)
    empty!(c, cache_type(c), unsigned(signal), recursive)
end

# force empty
function empty!(c::Cached; recursive=false)
    empty!(c, cache_type(c), recursive)
end

#################
# Implementation
#################

function empty!(c::Cached, ::Type{CT}, recursive::Bool) where CT
    if iscacheable(global_cache(CT), c)
        empty!(global_cache(CT), c.block)
    end
    c
end

function empty!(c::Cached, ::Type{CT}, recursive::Bool) where {CT <: CompositeBlock}
    if iscacheable(global_cache(CT), c)
        empty!(global_cache(CT), c.block)

        if recursive
            map(x->empty!(x, recursive=recursive), c.block)
        end
    end
end

function empty!(c::Cached, ::Type{CT}, signal::UInt, recursive::Bool) where CT
    if iscacheable(c, signal)
        empty!(c, CT, recursive)
    end
    c
end

function empty!(c::Cached, ::Type{CT}, signal::UInt, recursive::Bool) where {CT <: CompositeBlock}
    if iscacheable(global_cache(CT), c, signal)
        empty!(global_cache(CT), c.block)

        if recursive
            map(x->empty!(x, signal, recursive=recursive), c.block)
        end
    end
    c
end
