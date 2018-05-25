mutable struct CacheElement{TM <: AbstractMatrix}
    level::UInt
    data::Dict{Any, TM}

    CacheElement(::Type{TM}, level::UInt) where TM = new{TM}(level, Dict{Any, TM}())
end

iscacheable(c::CacheElement, level::UInt) = c.level < level
iscached(c::CacheElement, block::MatrixBlock) = block in keys(c.data)

function push!(c::CacheElement{TM}, k::MatrixBlock, v::TM) where TM
    c.data[k] = v
    c
end

function push!(c::CacheElement{TM}, k::MatrixBlock, v::TM, level::UInt) where TM
    iscacheable(c, level) || return c
    push!(c, k, v)
end

pull(c::CacheElement, k) = c.data[k]

function setlevel!(c::CacheElement, level::UInt)
    c.level = level
    c
end

empty!(c::CacheElement) = empty!(c.data)

function show(io::IO, c::CacheElement)
    println(io, "CacheElement(level: ", c.level, ")")
    println(io, c.data)
end
