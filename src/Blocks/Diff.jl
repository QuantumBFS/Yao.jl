export Rotor, generator, Diff

############# General Rotor ############
const Rotor{N, T} = Union{RotationGate{N, T}, PutBlock{N, <:Any, <:RotationGate, <:Complex{T}}}
"""
    generator(rot::Rotor) -> MatrixBlock

Return the generator of rotation block.
"""
generator(rot::RotationGate) = rot.block
generator(rot::PutBlock{N, C, GT}) where {N, C, GT<:RotationGate} = PutBlock{N}(generator(rot|>block), rot |> addrs)

"""
    Diff{N, T, GT<:Rotor{N, T}, RT<:AbstractRegister} <: AbstractContainer{N, Complex{T}}
    Diff(block, [output::AbstractRegister]) -> Diff

Mark a block as differentiable.

Warning:
    please don't use the `adjoint` after `Diff`! `adjoint` is reserved for special purpose! (back propagation)
"""
mutable struct Diff{N, T, GT<:Rotor{N, T}, RT<:AbstractRegister} <: TagBlock{N, Complex{T}}
    block::GT
    output::RT
    grad::T
    Diff(block::Rotor{N, T}, output::RT) where {N, T, RT} = new{N, T, typeof(block), RT}(block, output, T(0))
    Diff(block::Rotor{N, T}) where {N, T} = Diff(block, zero_state(N))
end
block(df::Diff) = df.block
chblock(cb::Diff, blk::Rotor) = Diff(blk)

@forward Diff.block mat
function apply!(reg::AbstractRegister, df::Diff)
    apply!(reg, parent(df))
    df.output = copy(reg)
    reg
end
function apply!(δ::AbstractRegister, adf::Daggered{<:Any, <:Any, <:Diff})
    df = adf |> parent
    df.grad = ((df.output |> generator(parent(df)))' * δ * 0.5im |> real)*2
    apply!(δ, parent(df)')
end

function print_block(io::IO, df::Diff)
    printstyled(io, "[∂] "; bold=true, color=:yellow)
    print_block(io, parent(df))
end
