export Adder

"""
    Adder{N, T} <: CompositeBlock{N, T}

Adding multiple blocks into one.
"""
struct Adder{N, T} <: CompositeBlock{N, T}
    blocks::Vector{MatrixBlock{N}}
end
# type promotion
function Adder(blocks::Vector{<:MatrixBlock{N}}) where N
    T = promote_type(collect(datatype(each) for each in blocks)...)
    Adder{N, T}(blocks)
end
function Adder(blocks::MatrixBlock{N}...) where N
    Adder(collect(blocks))
end

function copy(c::Adder{N, T}) where {N, T}
    Adder{N, T}(copy(c.blocks))
end

function similar(c::Adder{N, T}) where {N, T}
    Adder{N, T}(empty!(similar(c.blocks)))
end

# Additional Methods for Composite Blocks
@forward Adder.blocks lastindex, iterate, length, eltype, eachindex, popfirst!, pop!
getindex(c::Adder, index) = getindex(c.blocks, index)
getindex(c::Adder, index::Union{UnitRange, Vector}) = Adder(getindex(c.blocks, index))
setindex!(c::Adder{N}, val::MatrixBlock{N}, index::Integer) where N = (setindex!(c.blocks, val, index); c)
insert!(c::Adder{N}, index::Integer, val::MatrixBlock{N}) where N = (insert!(c.blocks, index, val); c)
adjoint(blk::Adder) = typeof(blk)(map(adjoint, subblocks(blk)))

## Iterate contained blocks
subblocks(c::Adder) = c.blocks
chsubblocks(pb::Adder, blocks) = Adder(blocks)
usedbits(c::Adder) = unique(vcat([usedbits(b) for b in subblocks(c)]...))

# Additional Methods for Adder
push!(c::Adder{N}, val::MatrixBlock{N}) where N = (push!(c.blocks, val); c)

function push!(c::Adder{N, T}, val::Function) where {N, T}
    push!(c, val(N))
end

function append!(c::Adder, list)
    for blk in list
        push!(c, blk)
    end
    c
end

function prepend!(c::Adder, list)
    for blk in list[end:-1:1]
        insert!(c, 1, blk)
    end
    c
end

mat(c::Adder) = mapreduce(x->mat(x), +, c.blocks)

function apply!(r::AbstractRegister, c::Adder)
    length(c) == 0 && return r
    res = mapreduce(blk->apply!(copy(r), blk), +, c.blocks[1:end-1])
    apply!(r, c.blocks[end])
    r.state += res.state
    r
end

function cache_key(c::Adder)
    [cache_key(each) for each in c.blocks]
end

function hash(c::Adder, h::UInt)
    hashkey = hash(objectid(c), h)
    for each in c.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function ==(lhs::Adder{N, T}, rhs::Adder{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::Adder)
    printstyled(io, "+"; bold=true, color=:red)
end

################# Arithmmatics #################
+(a::MatrixBlock{N}, b::MatrixBlock{N}) where N = Adder(a, b)
+(a::Adder{N, T1}, b::MatrixBlock{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([a.blocks...; b])
+(a::Adder{N, T1}, b::Adder{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([a.blocks...; b.blocks...])
+(a::MatrixBlock{N, T1}, b::Adder{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([a; b.blocks...])

*(a::Adder{N, T}, x::T2) where {N, T, T2<:Number} = Adder{N, promote_type(T, T2)}([b*x for b in subblocks(a)])
*(x::T2, a::Adder{N, T}) where {N, T, T2<:Number} = Adder{N, promote_type(T, T2)}([x*b for b in subblocks(a)])
*(y::Adder{N, T}, x::MatrixBlock{N, T2}) where {N, T, T2} = Adder{N, promote_type(T, T2)}([b*x for b in subblocks(y)])
*(x::MatrixBlock{N, T2}, y::Adder{N, T}) where {N, T, T2} = Adder{N, promote_type(T, T2)}([x*b for b in subblocks(y)])
*(x::ChainBlock{N, T1}, y::Adder{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([x*b for b in subblocks(y)])
*(x::Adder{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([b*y for b in subblocks(x)])
*(x::Adder{N, T1}, y::Adder{N, T2}) where {N, T1, T2} = Adder{N, promote_type(T1, T2)}([b*c for b in subblocks(x), c in subblocks(y)] |> vec)

*(x::MatrixBlock{N}, y::MatrixBlock{N}) where N = ChainBlock(y, x)
*(x::ChainBlock{N, T1}, y::MatrixBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y; x...])
*(x::MatrixBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x])
*(x::ChainBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x...])
*(g1::Scale, g2::ChainBlock) = Scale(parent(g1)*g2, factor(g1))
*(g2::ChainBlock, g1::Scale) = Scale(g2*parent(g1), factor(g1))
