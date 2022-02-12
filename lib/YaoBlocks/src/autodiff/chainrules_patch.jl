import ChainRulesCore:
    rrule, @non_differentiable, NoTangent, Tangent, backing, AbstractTangent, ZeroTangent

function create_circuit_tangent(circuit, params)
    gc = dispatch(circuit, params)
    res = recursive_create_tangent(gc)
    return res
end

# fallback
function recursive_create_tangent(c::AbstractBlock)
    if nparameters(c) == 0
        return NoTangent()
    else
        error("`Tangent` for type $(typeof(c)) is not defined!")
    end
end
# primitive blocks
unsafe_primitive_tangent(::Any) = NoTangent()
unsafe_primitive_tangent(x::Number) = x
for GT in [:RotationGate, :ShiftGate, :TimeEvolution, :PhaseGate]
    @eval function recursive_create_tangent(c::$GT)
        lst = map(fieldnames(typeof(c))) do fn
            fn => unsafe_primitive_tangent(getfield(c, fn))
        end
        nt = NamedTuple(lst)
        Tangent{typeof(c),typeof(nt)}(nt)
    end
end
# composite blocks
unsafe_composite_tangent(::Any) = NoTangent()
unsafe_composite_tangent(c::AbstractVector{<:AbstractBlock}) = recursive_create_tangent.(c)
unsafe_composite_tangent(c::AbstractBlock) = recursive_create_tangent(c)
for GT in [
    :ChainBlock,
    :Add,
    :KronBlock,
    :RepeatedBlock,
    :PutBlock,
    :Subroutine,
    :CachedBlock,
    :Daggered,
    :Scale,
]
    @eval function recursive_create_tangent(c::$GT)
        lst = map(fieldnames(typeof(c))) do fn
            fn => unsafe_composite_tangent(getfield(c, fn))
        end
        nt = NamedTuple(lst)
        Tangent{typeof(c),typeof(nt)}(nt)
    end
end

extract_circuit_gradients!(c::Number, output) = push!(output, c)
extract_circuit_gradients!(::Nothing, output) = output
extract_circuit_gradients!(::NoTangent, output) = output
extract_circuit_gradients!(::ZeroTangent, output) = output
function extract_circuit_gradients!(c::AbstractVector, output)
    for ci in c
        extract_circuit_gradients!(ci, output)
    end
    return output
end
function extract_circuit_gradients!(c::Tangent, output)
    for fn in getfield(c, :backing)
        extract_circuit_gradients!(fn, output)
    end
    return output
end
function extract_circuit_gradients!(c::NamedTuple, output)
    for fn in c
        extract_circuit_gradients!(fn, output)
    end
    return output
end

function rrule(::typeof(apply), reg::ArrayReg, block::AbstractBlock)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), outδ), block)
        return (NoTangent(), inδ, create_circuit_tangent(block, paramsδ))
    end
end
function rrule(::typeof(apply), reg::ArrayReg, block::Add)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), outδ), block; in = reg)
        return (NoTangent(), inδ, create_circuit_tangent(block, paramsδ))
    end
end


function rrule(::typeof(dispatch), block::AbstractBlock, params)
    out = dispatch(block, params)
    out, function (outδ::AbstractTangent)
        g = extract_circuit_gradients!(outδ, empty(params))
        res = (NoTangent(), NoTangent(), g)
        return res
    end
end

function rrule(::typeof(expect), op::AbstractBlock, reg::AbstractRegister{B}) where {B}
    out = expect(op, reg)
    out, function (outδ)
        greg = expect_g(op, reg)
        for b = 1:B
            viewbatch(greg, b).state .*= 2 * outδ[b]
        end
        return (NoTangent(), NoTangent(), greg)
    end
end

function rrule(
    ::typeof(expect),
    op::AbstractBlock,
    reg_and_circuit::Pair{<:ArrayReg{B},<:AbstractBlock},
) where {B}
    out = expect(op, reg_and_circuit)
    out,
    function (outδ)
        greg, gcircuit = expect_g(op, reg_and_circuit)
        for b = 1:B
            viewbatch(greg, b).state .*= 2 * outδ[b]
        end
        return (
            NoTangent(),
            NoTangent(),
            Tangent{typeof(reg_and_circuit)}(;
                first = greg,
                second = create_circuit_tangent(reg_and_circuit.second, gcircuit),
            ),
        )
    end
end

function rrule(::Type{T}, block::AbstractBlock) where {T<:Matrix}
    out = T(block)
    out, function (outδ)
        paramsδ = mat_back(block, outδ)
        return (NoTangent(), create_circuit_tangent(block, paramsδ))
    end
end

function rrule(::typeof(mat), ::Type{T}, block::AbstractBlock) where {T}
    out = mat(T, block)
    out, function (outδ)
        paramsδ = mat_back(block, outδ)
        return (NoTangent(), NoTangent(), create_circuit_tangent(block, paramsδ))
    end
end

function rrule(::Type{ArrayReg{B}}, raw::AbstractArray) where {B}
    ArrayReg{B}(raw), adjy -> (NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::Type{ArrayReg}, raw::AbstractArray)
    ArrayReg(raw), adjy -> (NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::typeof(copy), reg::ArrayReg) where {B}
    copy(reg), adjy -> (NoTangent(), adjy)
end

for (BT, BLOCKS) in [(:Add, :(outδ.list)) (:ChainBlock, :(outδ.blocks))]
    for ST in [:AbstractVector, :Tuple]
        @eval function rrule(::Type{BT}, source::$ST) where {N,BT<:$BT}
            out = BT(source)
            out, function (outδ)
                return (NoTangent(), $ST($BLOCKS))
            end
        end
    end
    @eval function rrule(::Type{BT}, args::AbstractBlock...) where {N,BT<:$BT}
        out = BT(args...)
        out, function (outδ)
            return (NoTangent(), $BLOCKS...)
        end
    end
end

_totype(::Type{T}, x::AbstractArray{T}) where {T} = x
_totype(::Type{T}, x::AbstractArray{T2}) where {T,T2} = convert.(T, x)
rrule(::typeof(state), reg::ArrayReg{B,D,T}) where {B,D,T} =
    state(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)))
rrule(::typeof(statevec), reg::ArrayReg{B,D,T}) where {B,D,T} =
    statevec(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)))
rrule(::typeof(state), reg::AdjointArrayReg{B,D,T}) where {B,D,T} =
    state(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)')')
rrule(::typeof(statevec), reg::AdjointArrayReg{B,D,T}) where {B,D,T} =
    statevec(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)')')
rrule(::typeof(parent), reg::AdjointArrayReg) = parent(reg), adjy -> (NoTangent(), adjy')
rrule(::typeof(Base.adjoint), reg::ArrayReg) =
    Base.adjoint(reg), adjy -> (NoTangent(), parent(adjy))
@non_differentiable nparameters(::Any)
@non_differentiable zero_state(args...)
@non_differentiable rand_state(args...)
@non_differentiable uniform_state(args...)
@non_differentiable product_state(args...)
