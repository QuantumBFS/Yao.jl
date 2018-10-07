export QDiff
"""
    QDiff{N, T, GT<:RotationGate{N, T}} <: TagBlock{N, Complex{T}}
    QDiff(block) -> QDiff

Mark a block as quantum differentiable.
"""
mutable struct QDiff{N, T, GT<:RotationGate{N, T}} <: TagBlock{N, Complex{T}}
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
