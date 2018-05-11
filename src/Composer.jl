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
    Sequence(seq)
end

function (c::Composer)(reg::Register)
    c(nqubit(reg))(reg)
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

function parse_block(b::Function, n::Int)
    b(n)
end