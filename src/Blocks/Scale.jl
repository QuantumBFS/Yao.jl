export AbstractScale, factor, chfactor
export Scale
export StaticScale, Pos, Neg, Im, _Im

"""
    AbstractScale{N, T} <: TagBlock{N, T}

Block for scaling siblings by a factor of X.
"""
abstract type AbstractScale{N, T} <: TagBlock{N, T} end

"""
    factor(blk::AbstractScale) -> Number

get scaling factor of `blk`.
"""
function factor end

"""
    chfactor(blk::AbstractScale) -> AbstractScale

change scaling factor of `blk`.
"""
function chfactor end

==(b1::AbstractScale, b2::AbstractScale) = parent(b1) == parent(b2) && factor(b1) == factor(b2)
==(b1::AbstractScale, b2::MatrixBlock) where X = parent(b1) == b2 && factor(b1) == 1
==(b1::MatrixBlock, b2::AbstractScale) where X = b1 == parent(b2) && factor(b2) == 1

mat(blk::AbstractScale) = factor(blk)*mat(blk |> parent)
datatype(blk::AbstractScale) = promote_type(typeof(factor(blk)), parent(blk) |> datatype)
apply!(reg::AbstractRegister, blk::AbstractScale) = factor(blk)*apply!(reg, blk |> parent)
adjoint(blk::AbstractScale) = chfactor(chblock(blk, parent(blk)), factor(blk)')

function print_block(io::IO, c::AbstractScale)
    printstyled(io, "[$(factor(c))] "; bold=true, color=:yellow)
    print_block(io, c |> parent)
end

############### Scale ##################
"""
    Scale{BT, FT, N, T} <: AbstractScale{N, T}

    Scale(block, factor) -> Scale

Scale Block.
"""
struct Scale{BT, FT, N, T} <: AbstractScale{N, T}
    block::BT
    factor::FT
end
Scale(blk::BT, factor::FT) where {N, T, FT, BT<:MatrixBlock{N, T}} = Scale{BT, FT, N, T}(blk, factor)
Scale(blk::AbstractScale) = Scale(blk |> parent, factor(blk))
Scale(blk::AbstractScale, α::Number) = Scale(blk |> parent, factor(blk)*α)

factor(blk::Scale) = blk.factor
chfactor(blk::Scale, factor::Number) = Scale(blk |> parent, factor)
adjoint(blk::Scale) = Scale(adjoint(blk.block), factor(blk)')

# take care of hash_key method!
similar(c::Scale) = Scale{X}(similar(c.block), one(factor(c)))
copy(c::Scale) = Scale(copy(c.block), c |> factor)
chblock(sb::Scale, blk::MatrixBlock) = Scale(blk, sb|>factor)

LinearAlgebra.rmul!(s::Scale{<:Any, FT}, factor::Number) where FT = (s.factor = FT(s.factor*factor); s)
LinearAlgebra.lmul!(factor::Number, s::Scale{<:Any, FT}) where FT = (s.factor = FT(factor*s.factor); s)

############### StaticScale ##################
"""
    StaticScale{X, BT, N, T} <: AbstractScale{N, T}

    StaticScale{X}(blk::MatrixBlock)
    StaticScale{X, N, T, BT}(blk::MatrixBlock)

Scale Block, by a static factor of X, notice X is static!
"""
struct StaticScale{X, BT, N, T} <: AbstractScale{N, T}
    block::BT
end
StaticScale{X}(blk::BT) where {X, N, T, BT<:MatrixBlock{N, T}} = StaticScale{X, BT, N, T}(blk)
StaticScale(blk::MatrixBlock, x::Number) = StaticScale{x}(blk)
StaticScale(blk::AbstractScale) = StaticScale{factor(X)}(blk |> parent)
StaticScale(blk::AbstractScale, α::Number) = StaticScale{factor(blk)*α}(blk |> parent)

factor(blk::StaticScale{X}) where X = X
chfactor(blk::StaticScale, factor::Number) = StaticScale{factor}(blk |> parent)

# since adjoint can propagate, this way is better
adjoint(blk::StaticScale{X}) where X = StaticScale{X'}(adjoint(blk.block))

# take care of hash_key method!
similar(c::StaticScale{X}) where X = StaticScale{X}(similar(c.block))
copy(c::StaticScale{X}) where X = StaticScale{X}(copy(c.block))
chblock(pb::StaticScale{X}, blk::MatrixBlock) where {X} = StaticScale{X}(blk)

const Pos{BT, N, T} = StaticScale{1+0im, BT, N, T}
const Neg{BT, N, T} = StaticScale{-1+0im, BT, N, T}
const Im{BT, N, T} = StaticScale{1im, BT, N, T}
const _Im{BT, N, T} = StaticScale{-1im, BT, N, T}

function print_block(io::IO, c::Pos)
    printstyled(io, "[+] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::Neg)
    printstyled(io, "[-] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::Im)
    printstyled(io, "[i] "; bold=true, color=:yellow)
    print_block(io, c.block)
end

function print_block(io::IO, c::_Im)
    printstyled(io, "[-i] "; bold=true, color=:yellow)
    print_block(io, c.block)
end
