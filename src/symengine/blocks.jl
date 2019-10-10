using YaoBlocks, SymEngine, LuxurySparse, LinearAlgebra

Base.promote_rule(::Type{Bool}, ::Type{Basic}) = Basic
Base.conj(x::Basic) = real(x) - imag(x)

const SymReal = Union{Basic, SymEngine.BasicRealNumber}
YaoBlocks.RotationGate(block::GT, theta::T) where {N, T <: SymReal, GT<:AbstractBlock{N}} = RotationGate{N, T, GT}(block, theta)

YaoBlocks.phase(θ::SymReal) = PhaseGate(θ)
YaoBlocks.shift(θ::SymReal) = ShiftGate(θ)

YaoBlocks.mat(::Type{Basic}, ::HGate) = 1/sqrt(Basic(2)) * Basic[1 1;1 -1]
YaoBlocks.mat(::Type{Basic}, ::XGate) = Basic[0 1;1 0]
YaoBlocks.mat(::Type{Basic}, ::YGate) = Basic[0 -1im;1im 0]
YaoBlocks.mat(::Type{Basic}, ::ZGate) = Basic[1 0;0 -1]

YaoBlocks.mat(gate::ShiftGate{<:SymReal}) =
    Diagonal([1.0, exp(im * gate.theta)])
YaoBlocks.mat(gate::PhaseGate{<:SymReal}) =
    exp(im * gate.theta) * IMatrix{2}()
function YaoBlocks.mat(R::RotationGate{N, <:SymReal}) where N
    I = IMatrix{1<<N}()
    return I * cos(R.theta / 2) - im * sin(R.theta / 2) * mat(Basic,R.block)
end

YaoBlocks.PSwap{N}(locs::Tuple{Int, Int}, θ::SymReal) where N = YaoBlocks.PutBlock{N}(rot(ConstGate.SWAPGate(), θ), locs)

YaoBlocks.pswap(n::Int, i::Int, j::Int, α::SymReal) = PSwap{n}((i,j), α)
YaoBlocks.pswap(i::Int, j::Int, α::SymReal) = n->pswap(n,i,j,α)
