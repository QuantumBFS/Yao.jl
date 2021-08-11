import ChainRulesCore: rrule, @non_differentiable, NoTangent
using Yao, Yao.AD

function rrule(::typeof(apply!), reg::ArrayReg, block::AbstractBlock)
    out = apply!(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((out, outδ), block)
        return (NoTangent(), inδ, paramsδ)
    end
end

function rrule(::typeof(dispatch!), block::AbstractBlock, params)
    out = dispatch!(block, params)
    out, function (outδ)
        (NoTangent(), NoTangent(), outδ)
    end
end

function rrule(::typeof(expect), op::AbstractBlock, reg::AbstractRegister{B}) where {B}
    out = expect(op, reg)
    out, function (outδ)
        greg = Yao.AD.expect_g(op, reg)
        for b=1:B
            viewbatch(greg, b).state .*= 2*outδ[b]
        end
        return (NoTangent(), NoTangent(), greg)
    end
end

function rrule(::Type{Matrix}, block::AbstractBlock)
    out = Matrix(block)
    out, function (outδ)
        paramsδ = mat_back(block, outδ)
        return (NoTangent(), paramsδ)
    end
end

function rrule(::Type{ArrayReg{B}}, raw::AbstractArray) where B
    ArrayReg{B}(raw), adjy->(NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::Type{ArrayReg{B}}, raw::ArrayReg) where B
    ArrayReg{B}(raw), adjy->(NoTangent(), adjy)
end

function rrule(::Type{ArrayReg}, raw::AbstractArray)
    ArrayReg(raw), adjy->(NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::typeof(copy), reg::ArrayReg) where B
    copy(reg), adjy->(NoTangent(), adjy)
end

rrule(::typeof(state), reg::ArrayReg) = state(reg), adjy->(NoTangent(), ArrayReg(adjy))
rrule(::typeof(statevec), reg::ArrayReg) = statevec(reg), adjy->(NoTangent(), ArrayReg(adjy))
rrule(::typeof(state), reg::AdjointArrayReg) = state(reg), adjy->(NoTangent(), ArrayReg(adjy')')
rrule(::typeof(statevec), reg::AdjointArrayReg) = statevec(reg), adjy->(NoTangent(), ArrayReg(adjy')')
rrule(::typeof(parent), reg::AdjointArrayReg) = parent(reg), adjy->(NoTangent(), adjy')
rrule(::typeof(Base.adjoint), reg::ArrayReg) = Base.adjoint(reg), adjy->(NoTangent(), parent(adjy))
@non_differentiable Yao.nparameters(::Any)
@non_differentiable Yao.zero_state(args...)
@non_differentiable Yao.rand_state(args...)
@non_differentiable Yao.uniform_state(args...)
@non_differentiable Yao.product_state(args...)
