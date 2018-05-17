struct Composer
    fs::Vector
end

export compose

compose(seq::Vector) = Composer(seq)
compose(fs...) = compose([fs...])

"""
    parse_block

plugable argument transformer, overload this for different interface.
"""
function parse_block end

function (c::Composer)(n::Int) # -> circuit{n}
    seq = []
    for each in c.fs
        push!(seq, parse_block(each, n)) # each is a block factory function
    end
    chain(seq...)
end

function (c::Composer)(reg::Register)
    c(nqubit(reg))(reg)
end

function show(io::IO, c::Composer)
    for each in c.fs
        println(io, each)
    end
end

function parse_block(b::Tuple{BT, Int}, n::Int) where BT
    block, pos = b
    @assert n >= pos "input size is too small"
    kron(n, (pos, block))
end

function parse_block(b::Tuple{BT, I}, n::Int) where {BT, I <: UnitRange}
    block, itr = b
    @assert n >= maximum(itr) "input size is too small"
    kron(n, (i, block) for i in itr)
end

function parse_block(b::AbstractBlock, n::Int)
    b
end

# default fallback method
function parse_block(b, n::Int)
    b(n)
end

## Interface Overloads

# chain

chain(fs...) = x->chain([each(x) for each in fs])

# cached
cache(f, level::Int=1;recursive::Bool=false) = x->cache(f(x), level; recursive=recursive)

import Base: map
"""
    map(block)

map this block to all lines
"""
map(b::MatrixBlock) = n->kron(b for i=1:n)
