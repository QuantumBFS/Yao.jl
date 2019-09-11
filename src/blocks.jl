using YaoBlocks, SymEngine, LuxurySparse, LinearAlgebra

Base.promote_rule(::Type{Bool}, ::Type{Basic}) = Basic
Base.conj(x::Basic) = real(x) - imag(x)

const SymReal = Union{Basic, SymEngine.BasicRealNumber}
YaoBlocks.RotationGate(block::GT, theta::T) where {N, T <: SymReal, GT<:AbstractBlock{N}} = RotationGate{N, T, GT}(block, theta)

YaoBlocks.phase(θ::SymReal) = PhaseGate(θ)
YaoBlocks.shift(θ::SymReal) = ShiftGate(θ)

YaoBlocks.mat(gate::ShiftGate{<:SymReal}) =
    Diagonal([1.0, exp(im * gate.theta)])
YaoBlocks.mat(gate::PhaseGate{<:SymReal}) =
    exp(im * gate.theta) * IMatrix{2}()
function YaoBlocks.mat(R::RotationGate{N, <:SymReal}) where N
    I = IMatrix{1<<N}()
    return I * cos(R.theta / 2) - im * sin(R.theta / 2) * mat(R.block)
end

YaoBlocks.mat(::Type{<:Any}, gate::PhaseGate{<:SymReal}) = mat(gate)
YaoBlocks.mat(::Type{<:Any}, gate::ShiftGate{<:SymReal}) = mat(gate)
YaoBlocks.mat(::Type{<:Any}, gate::RotationGate{N, <:SymReal}) = mat(gate)
