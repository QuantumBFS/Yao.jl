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
    QDiff{GT, N, T} <: AbstractDiff{N, Complex{T}}
    QDiff(block) -> QDiff

Mark a block as quantum differentiable.
"""
mutable struct QDiff{GT, N, T} <: AbstractDiff{N, Complex{T}}
    block::GT
    grad::T
    QDiff(block::RotationGate{N, T}) where {N, T} = new{typeof(block), N, T}(block, T(0))
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
    BPDiff{GT, N, T, PT, RT<:AbstractRegister} <: AbstractDiff{N, Complex{T}}
    BPDiff(block, [input::AbstractRegister, grad]) -> BPDiff

Mark a block as differentiable, here `GT`, `PT` and `RT` are gate type, parameter type and register type respectively.

Warning:
    please don't use the `adjoint` after `BPDiff`! `adjoint` is reserved for special purpose! (back propagation)
"""
mutable struct BPDiff{GT, N, T, PT, RT<:AbstractRegister} <: AbstractDiff{N, T}
    block::GT
    input::RT
    grad::PT
    BPDiff(block::MatrixBlock{N, T}, input::RT, grad::PT) where {N, T, PT, RT} = new{typeof(block), N, T, typeof(grad), RT}(block, input, grad)
end
BPDiff(block::MatrixBlock, input::AbstractRegister) = BPDiff(block, input, zeros(iparameter_type(block), niparameters(block)))
BPDiff(block::MatrixBlock{N, T}) where {N, T} = BPDiff(block, zero_state(N))
BPDiff(block::Rotor{N, T}, input::AbstractRegister) where {N, T} = BPDiff(block, input, T(0))

chblock(cb::BPDiff, blk::MatrixBlock) = BPDiff(blk)

@forward BPDiff.block mat
function apply!(reg::AbstractRegister, df::BPDiff)
    copyto!(df.input, copy(reg))
    apply!(reg, parent(df))
    reg
end

function apply!(δ::AbstractRegister, adf::Daggered{<:BPDiff{<:Rotor}})
    df = adf |> parent
    δ = apply!(δ, parent(df)')
    df.grad = -statevec(df.input |> generator(parent(df)))' * statevec(δ) |> imag
    δ
end

function print_block(io::IO, df::BPDiff)
    printstyled(io, "[∂] "; bold=true, color=:yellow)
    print_block(io, parent(df))
end
