export Rotor, generator, AbstractDiff, BPDiff, QDiff

############# General Rotor ############
const Rotor{N, T} = Union{RotationGate{N, T}, PutBlock{N, <:Any, <:RotationGate, <:Complex{T}}}
"""
    generator(rot::Rotor) -> MatrixBlock

Return the generator of rotation block.
"""
generator(rot::RotationGate) = rot.block
generator(rot::PutBlock{N, C, GT}) where {N, C, GT<:RotationGate} = PutBlock{N}(generator(rot|>block), rot |> addrs)

abstract type AbstractDiff{N, T} <: TagBlock{N, T} end

#################### The Basic Diff #################
"""
    QDiff{N, T, GT<:RotationGate{N, T}} <: TagBlock{N, Complex{T}}
    QDiff(block) -> QDiff

Mark a block as quantum differentiable.
"""
mutable struct QDiff{N, T, GT<:RotationGate{N, T}} <: AbstractDiff{N, Complex{T}}
    block::GT
    grad::T
    QDiff(block::RotationGate{N, T}) where {N, T} = new{N, T, typeof(block)}(block, T(0))
end
chblock(cb::QDiff, blk::RotationGate) = QDiff(blk)

@forward QDiff.block mat, apply!
adjoint(df::QDiff) = QDiff(parent(df)')

function print_block(io::IO, df::QDiff)
    printstyled(io, "[̂∂] "; bold=true, color=:yellow)
    print(io, parent(df))
end

#################### The Back Propagation Diff #################
"""
    BPDiff{N, T, GT<:Rotor{N, T}, RT<:AbstractRegister} <: TagBlock{N, Complex{T}}
    BPDiff(block, [output::AbstractRegister]) -> BPDiff

Mark a block as differentiable.

Warning:
    please don't use the `adjoint` after `BPDiff`! `adjoint` is reserved for special purpose! (back propagation)
"""
mutable struct BPDiff{N, T, GT<:Rotor{N, T}, RT<:AbstractRegister} <: AbstractDiff{N, Complex{T}}
    block::GT
    output::RT
    grad::T
    BPDiff(block::Rotor{N, T}, output::RT) where {N, T, RT} = new{N, T, typeof(block), RT}(block, output, T(0))
    BPDiff(block::Rotor{N, T}) where {N, T} = BPDiff(block, zero_state(N))
end
chblock(cb::BPDiff, blk::Rotor) = BPDiff(blk)

@forward BPDiff.block mat
function apply!(reg::AbstractRegister, df::BPDiff)
    apply!(reg, parent(df))
    df.output = copy(reg)
    reg
end
function apply!(δ::AbstractRegister, adf::Daggered{<:Any, <:Any, <:BPDiff})
    df = adf |> parent
    df.grad = ((df.output |> generator(parent(df)))' * δ * 0.5im |> real)*2
    apply!(δ, parent(df)')
end

function print_block(io::IO, df::BPDiff)
    printstyled(io, "[∂] "; bold=true, color=:yellow)
    print_block(io, parent(df))
end
