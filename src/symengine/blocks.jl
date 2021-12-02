using YaoBlocks
using LuxurySparse
using LinearAlgebra
using ..SymEngine
using ..SymEngine: BasicType, BasicOp, BasicTrigFunction

op_types = [:Mul, :Add, :Pow]
const BiVarOp = Union{[SymEngine.BasicType{Val{i}} for i in op_types]...}

export @vars

simag = SymFunction("Im")
sreal = SymFunction("Re")
sabs = SymFunction("abs")

Base.promote_rule(::Type{Bool}, ::Type{Basic}) = Basic
Base.conj(x::Basic) = Basic(conj(SymEngine.BasicType(x)))
Base.conj(x::BasicType) = real(x) - im * imag(x)
Base.conj(x::BiVarOp) = juliafunc(x)(conj.(get_args(x.x))...)
Base.conj(x::BasicTrigFunction) = juliafunc(x)(conj.(get_args(x.x)...)...)
# WARNING: symbols and constants are assumed real!
Base.imag(x::BasicType{Val{:Constant}}) = Basic(0)
Base.imag(x::BasicType{Val{:Symbol}}) = Basic(0)
Base.abs(x::Basic) = Basic(abs(SymEngine.BasicType(x)))
Base.abs(x::BasicType{Val{:Constant}}) = x
Base.abs(x::BasicType{Val{:Symbol}}) = x
function Base.imag(x::BasicType{Val{:Add}})
    args = get_args(x.x)
    mapreduce(imag, +, args)
end

function Base.real(x::BasicType{Val{:Add}})
    args = get_args(x.x)
    mapreduce(real, +, args)
end

function Base.abs(x::BasicType{Val{:Add}})
    args = get_args(x.x)
    mapreduce(abs, +, args)
end

function Base.imag(x::BasicType{Val{:Mul}})
    args = (get_args(x.x)...,)
    get_mul_imag(args)
end

function Base.real(x::BasicType{Val{:Pow}})
    a, b = get_args(x.x)
    if imag(a) == 0 && imag(b) == 0
        return x.x
    else
        if imag(a) == 0
            return a^real(b) * cos(log(a) * imag(b))
        else
            return sreal(x.x)
        end
    end
end

function Base.imag(x::BasicType{Val{:Pow}})
    a, b = get_args(x.x)
    if imag(a) == 0 && imag(b) == 0
        return Basic(0)
    else
        if imag(a) == 0
            return a^real(b) * sin(log(a) * imag(b))
        else
            return simag(x.x)
        end
    end
end

function Base.abs(x::BasicType{Val{:Pow}})
    a, b = get_args(x.x)
    abs(a)^real(b)
end

function Base.real(x::BasicType{Val{:Mul}})
    args = (get_args(x.x)...,)
    get_mul_real(args)
end

function get_mul_imag(args::NTuple{N,Any}) where {N}
    imag(args[1]) * get_mul_real(args[2:end]) + real(args[1]) * get_mul_imag(args[2:end])
end
get_mul_imag(args::Tuple{Basic}) = imag(args[1])

function get_mul_real(args::NTuple{N,Any}) where {N}
    real(args[1]) * get_mul_real(args[2:end]) - imag(args[1]) * get_mul_imag(args[2:end])
end
get_mul_real(args::Tuple{Basic}) = real(args[1])

function Base.real(x::BasicTrigFunction)
    a, = get_args(x.x)
    if imag(a) == 0
        return x.x
    else
        return sreal(x.x)
    end
end

function Base.abs(x::BasicTrigFunction)
    a, = get_args(x.x)
    if imag(a) == 0
        return x.x
    else
        return sabs(x.x)
    end
end

function Base.imag(x::BasicTrigFunction)
    a, = get_args(x.x)
    if imag(a) == 0
        return Basic(0)
    else
        return simag(x.x)
    end
end

@generated function juliafunc(x::BasicType{Val{T}}) where {T}
    SymEngine.map_fn(T, SymEngine.fn_map)
end

const SymReal = Union{Basic,SymEngine.BasicRealNumber}
YaoBlocks.RotationGate(block::GT, theta::T) where {N,T<:SymReal,GT<:AbstractBlock{N}} =
    RotationGate{N,T,GT}(block, theta)

YaoBlocks.phase(θ::SymReal) = PhaseGate(θ)
YaoBlocks.shift(θ::SymReal) = ShiftGate(θ)

YaoBlocks.mat(::Type{Basic}, gate::GT) where GT<:ConstantGate = _pretty_basic.(mat(gate))
YaoBlocks.mat(::Type{Basic}, gate::ConstGate.TGate) = Diagonal(Basic[1, exp(Basic(im)*Basic(π)/4)])
YaoBlocks.mat(::Type{Basic}, gate::ConstGate.TdagGate) = Diagonal(Basic[1, exp(-Basic(im)*Basic(π)/4)])
YaoBlocks.mat(::Type{Basic}, ::HGate) = 1 / sqrt(Basic(2)) * Basic[1 1; 1 -1]
YaoBlocks.mat(::Type{Basic}, gate::ShiftGate) = Diagonal([1, exp(im * gate.theta)])
YaoBlocks.mat(::Type{Basic}, gate::PhaseGate) = exp(im * gate.theta) * IMatrix{2}()
function YaoBlocks.mat(::Type{Basic}, R::RotationGate{N}) where {N}
    I = IMatrix{1 << N}()
    return I * cos(R.theta / 2) - im * sin(R.theta / 2) * mat(Basic, R.block)
end
for GT in [:XGate, :YGate, :ZGate]
    @eval YaoBlocks.mat(::Type{Basic}, R::RotationGate{1,T,<:$GT}) where {T} =
        invoke(mat, Tuple{Type{Basic},RotationGate}, Basic, R)
end

for T in [:(RotationGate{N,<:SymReal}), :(PhaseGate{<:SymReal}), :(ShiftGate{<:SymReal})]
    @eval YaoBlocks.mat(gate::$T) = mat(Basic, gate)
end

YaoBlocks.PSwap{N}(locs::Tuple{Int,Int}, θ::SymReal) where {N} =
    YaoBlocks.PutBlock{N}(rot(ConstGate.SWAPGate(), θ), locs)

YaoBlocks.pswap(n::Int, i::Int, j::Int, α::SymReal) = PSwap{n}((i, j), α)
YaoBlocks.pswap(i::Int, j::Int, α::SymReal) = n -> pswap(n, i, j, α)

export subs, chiparams
chiparams(blk::RotationGate, param) = rot(blk.block, param)
chiparams(blk::ShiftGate, param) = shift(param)
chiparams(blk::PhaseGate, param) = phase(param)
chiparams(blk::TimeEvolution, param) = time_evolve(blk.H, param, tol = blk.tol)
chiparams(blk::AbstractBlock, params...) =
    niparams(blk) == length(params) == 0 ? blk :
    throw(NotImplementedError(:chiparams, (blk, params...)))

SymEngine.subs(c::AbstractBlock, args...; kwargs...) = subs(Basic, c, args...; kwargs...)
function SymEngine.subs(::Type{T}, c::AbstractBlock, args...; kwargs...) where {T}
    c = chiparams(c, map(x -> T(subs(x, args...; kwargs...)), getiparams(c))...)
    chsubblocks(c, [subs(T, blk, args..., kwargs...) for blk in subblocks(c)])
end

# dumpload
YaoBlocks.tokenize_param(param::Basic) = QuoteNode(Symbol(param))
YaoBlocks.parse_param(x::QuoteNode) = :(Basic($x))
