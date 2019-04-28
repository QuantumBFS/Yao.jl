using YaoBase
using BitBasis: BitStr
# NOTE: this file should only exists in v0.4.x
#       since in v0.4.x the conponent packages
#       are all new packages and should not have
#       deprecation warning itself.

# Base
@deprecate addbit!(r::AbstractRegister, n::Int) addbits!(r, n)
@deprecate addbit!(n::Int) addbits!(n)
@deprecate reset!(r::AbstractRegister; val::Integer=0)  collapseto!(r, val)
@deprecate measure_reset!(r::AbstractRegister; val::Int=0) measure_collapseto!(r; config=val)
@deprecate measure_reset!(r::AbstractRegister, locs; val::Int=0) measure_collapseto!(r, locs; config=val)

# ArrayReg
@deprecate register(raw::AbstractMatrix; B=size(raw,2)) ArrayReg{B}(raw)
@deprecate register(raw::AbstractVector) ArrayReg(raw)
@deprecate register(bits::BitStr, nbatch::Int=1) ArrayReg{nbatch}(bits)
@deprecate register(::Type{T}, bits::BitStr, nbatch::Int) where T ArrayReg{nbatch}(T, bits)

@deprecate usedbits(block::AbstractBlock{N}) where N occupied_locs(block)

################ Compatibility Code ###################
export DefaultRegister, MatrixBlock, Sequential, ReflectBlock, GeneralMatrixGate, AddBlock, ⊗
const DefaultRegister = ArrayReg
const MatrixBlock = AbstractBlock
const Sequential = ChainBlock
const ReflectBlock = ReflectGate
const GeneralMatrixGate = GeneralMatrixBlock
const AddBlock = Sum

@deprecate sequence(args...) chain(args...)
@deprecate matrixgate(args...) matblock(args...)

import Base: collect, parent
@deprecate collect(t::Type, x::AbstractBlock) collect_blocks(t, x)

# joining two registers
⊗(reg::AbstractRegister, reg2::AbstractRegister) = join(reg, reg2)
⊗(A::AbstractArray, B::AbstractArray) = kron(A, B)

# Originally addrs means return the addression stored in a composite block
# this is not necessary since not all composite block store the address, e.g
# roller, etc.
# @deprecate addrs(block::AbstractBlock) occupied_locs(block)

# NOTE: block is frequently used as variable name, to make sure there is
#       no conflicts, this is commented.
@deprecate block(x::AbstractContainer) content(x)
@deprecate parent(x::AbstractContainer) content(x)
@deprecate chblock(x::AbstractContainer, blk::AbstractBlock) chsubblocks(x, blk)

@deprecate timeevolve(block::MatrixBlock, t::Number; tol::Real=1e-7) time_evolve(block, t; tol=tol)
@deprecate timeevolve(t::Number; tol::Real=1e-7) time_evolve(t; tol=tol)


import Base: collect, *
@deprecate collect(x::AbstractBlock, ::Type{T}) where {T <: AbstractBlock} collect_blocks(T, x)

function Base.:*(op::AbstractMatrix, r::ArrayRegOrAdjointArrayReg)
    Base.depwarn("`matrix * register` is deprecated")
    return op * state(r)
end
