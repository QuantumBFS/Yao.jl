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

function dispatch!(c::Composer, params)
    for each in fs
    end
end

function (c::Composer)(reg::AbstractRegister)
    c(nqubits(reg))(reg)
end

function show(io::IO, c::Composer)
    for each in c.fs
        println(io, each)
    end
end

function parse_block(b::RangedBlock{BT, Int}, n::Int) where BT
    block, pos = b.block, b.range
    @assert n >= pos "input size is too small"
    kron(n, pos=>block)
end

function parse_block(b::RangedBlock{BT, I}, n::Int) where {BT, I}
    block, itr = b.block, b.range
    @assert n >= maximum(itr) "input size is too small"
    kron(n, i=>block for i in itr)
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

# # cached
# cache(f::Function, level::Int=1;recursive::Bool=false) = x->cache(f(x), level; recursive=recursive)
# cache(level::Int=1;recursive::Bool=false) = x->cache(x, level; recursive=recursive)
