import ChainRulesCore: rrule, @non_differentiable, NoTangent, Tangent

function rrule(::typeof(apply), reg::ArrayReg, block::AbstractBlock)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), outδ), block)
        return (NoTangent(), inδ, dispatch(block, paramsδ))
    end
end

function rrule(::typeof(apply), reg::ArrayReg, block::Add)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), outδ), block; in = reg)
        return (NoTangent(), inδ, dispatch(block, paramsδ))
    end
end

function rrule(::typeof(dispatch), block::AbstractBlock, params)
    out = dispatch(block, params)
    out, function (outδ)
        (NoTangent(), NoTangent(), parameters(outδ))
    end
end

function rrule(::typeof(expect), op::AbstractBlock, reg::AbstractRegister{B}) where {B}
    out = expect(op, reg)
    out, function (outδ)
        greg = expect_g(op, reg)
        for b in 1:B
            viewbatch(greg, b).state .*= 2 * outδ[b]
        end
        return (NoTangent(), NoTangent(), greg)
    end
end

function rrule(::typeof(expect), op::AbstractBlock, reg_and_circuit::Pair{<:ArrayReg{B},<:AbstractBlock}) where {B}
    out = expect(op, reg_and_circuit)
    out, function (outδ)
        greg, gcircuit = expect_g(op, reg_and_circuit)
        for b in 1:B
            viewbatch(greg, b).state .*= 2 * outδ[b]
        end
        return (NoTangent(), NoTangent(), Tangent{typeof(reg_and_circuit)}(; first=greg, second=dispatch(reg_and_circuit.second, gcircuit)))
    end
end

function rrule(::Type{T}, block::AbstractBlock) where T<:Matrix
    out = T(block)
    out, function (outδ)
        paramsδ = mat_back(block, outδ)
        return (NoTangent(), dispatch(block, paramsδ))
    end
end

function rrule(::typeof(mat), ::Type{T}, block::AbstractBlock) where T
    out = mat(T, block)
    out, function (outδ)
        paramsδ = mat_back(block, outδ)
        return (NoTangent(), NoTangent(), dispatch(block, paramsδ))
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

_totype(::Type{T}, x::AbstractArray{T}) where {T} = x
_totype(::Type{T}, x::AbstractArray{T2}) where {T,T2} = convert.(T, x)
rrule(::typeof(state), reg::ArrayReg{B,T}) where {B,T} =
    state(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)))
rrule(::typeof(statevec), reg::ArrayReg{B,T}) where {B,T} =
    statevec(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)))
rrule(::typeof(state), reg::AdjointArrayReg{B,T}) where {B,T} =
    state(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)')')
rrule(::typeof(statevec), reg::AdjointArrayReg{B,T}) where {B,T} =
    statevec(reg), adjy -> (NoTangent(), ArrayReg(_totype(T, adjy)')')
rrule(::typeof(parent), reg::AdjointArrayReg) = parent(reg), adjy -> (NoTangent(), adjy')
rrule(::typeof(Base.adjoint), reg::ArrayReg) = Base.adjoint(reg), adjy -> (NoTangent(), parent(adjy))
@non_differentiable nparameters(::Any)
@non_differentiable zero_state(args...)
@non_differentiable rand_state(args...)
@non_differentiable uniform_state(args...)
@non_differentiable product_state(args...)
