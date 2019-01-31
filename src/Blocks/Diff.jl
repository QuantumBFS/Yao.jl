export Rotor, generator, AbstractDiff, BPDiff, QDiff

############# General Rotor ############
const Rotor{N, T} = Union{RotationGate{N, T}, PutBlock{N, <:Any, <:RotationGate, <:Complex{T}}}
"""
    generator(rot::Rotor) -> MatrixBlock

Return the generator of rotation block.
"""
generator(rot::RotationGate) = rot.block
generator(rot::PutBlock{N, C, GT}) where {N, C, GT<:RotationGate} = PutBlock{N}(generator(rot|>block), rot |> addrs)

abstract type AbstractDiff{GT, N, T} <: TagBlock{N, T} end
adjoint(df::AbstractDiff) = Daggered(df)

istraitkeeper(::AbstractDiff) = Val(true)

#################### The Basic Diff #################
"""
    QDiff{GT, N, T} <: AbstractDiff{GT, N, Complex{T}}
    QDiff(block) -> QDiff

Mark a block as quantum differentiable.
"""
mutable struct QDiff{GT, N, T} <: AbstractDiff{GT, N, Complex{T}}
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
    BPDiff{GT, N, T, PT} <: AbstractDiff{GT, N, Complex{T}}
    BPDiff(block, [grad]) -> BPDiff

Mark a block as differentiable, here `GT`, `PT` is gate type, parameter type.

Warning:
    please don't use the `adjoint` after `BPDiff`! `adjoint` is reserved for special purpose! (back propagation)
"""
mutable struct BPDiff{GT, N, T, PT} <: AbstractDiff{GT, N, T}
    block::GT
    grad::PT
    input::AbstractRegister
    BPDiff(block::MatrixBlock{N, T}, grad::PT) where {N, T, PT} = new{typeof(block), N, T, typeof(grad)}(block, grad)
end
BPDiff(block::MatrixBlock) = BPDiff(block, zeros(iparameter_type(block), niparameters(block)))
BPDiff(block::Rotor{N, T}) where {N, T} = BPDiff(block, T(0))

chblock(cb::BPDiff, blk::MatrixBlock) = BPDiff(blk)

@forward BPDiff.block mat
function apply!(reg::AbstractRegister, df::BPDiff)
    if isdefined(df, :input)
        copyto!(df.input, reg)
    else
        df.input = copy(reg)
    end
    apply!(reg, parent(df))
    reg
end

function apply!(δ::AbstractRegister, adf::Daggered{<:BPDiff{<:Rotor}})
    df = adf |> parent
    apply!(δ, parent(df)')
    df.grad = -statevec(df.input |> generator(parent(df)))' * statevec(δ) |> imag
    δ
end

function print_block(io::IO, df::BPDiff)
    printstyled(io, "[∂] "; bold=true, color=:yellow)
    print_block(io, parent(df))
end
