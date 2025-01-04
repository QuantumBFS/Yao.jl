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
for GT in [:RotationGate, :ShiftGate, :PhaseGate, :(Scale{<:Number})]
    @eval function recursive_create_tangent(c::$GT)
        lst = map(fieldnames(typeof(c))) do fn
            fn => unsafe_primitive_tangent(unthunk(getfield(c, fn)))
        end
        nt = NamedTuple(lst)
        Tangent{typeof(c),typeof(nt)}(nt)
    end
end
function recursive_create_tangent(c::TimeEvolution)
    Tangent{typeof(c)}(; H=NoTangent(), dt=c.dt, tol=NoTangent())
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
    :ControlBlock,
    :Subroutine,
    :CachedBlock,
    :Daggered,
    :Scale,
]
    @eval function recursive_create_tangent(c::$GT)
        lst = map(fieldnames(typeof(c))) do fn
            fn => unsafe_composite_tangent(unthunk(getfield(c, fn)))
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

function rrule(::typeof(apply), reg::AbstractArrayReg, block::AbstractBlock)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), tangent_to_reg(typeof(out), outδ)), block)
        return (NoTangent(), inδ, create_circuit_tangent(block, paramsδ))
    end
end
function rrule(::typeof(apply), reg::AbstractArrayReg, block::AbstractAdd)
    out = apply(reg, block)
    out, function (outδ)
        (in, inδ), paramsδ = apply_back((copy(out), tangent_to_reg(typeof(out), outδ)), block; in = reg)
        return (NoTangent(), inδ, create_circuit_tangent(block, paramsδ))
    end
end
tangent_to_reg(::Type{T}, reg) where T<:AbstractArrayReg = reg isa Tangent ? T(reg.state) : reg


function rrule(::typeof(dispatch), block::AbstractBlock, params)
    out = dispatch(block, params)
    out, function (outδ::AbstractTangent)
        g = extract_circuit_gradients!(outδ, empty(params))
        res = (NoTangent(), NoTangent(), g)
        return res
    end
end

function rrule(::typeof(expect), op::AbstractBlock, reg::AbstractArrayReg)
    B = YaoArrayRegister._asint(nbatch(reg))
    out = expect(op, reg)
    out, function (outδ)
        greg = expect_g(op, reg)
        for b = 1:B
            viewbatch(greg, b).state .*= outδ[b]
        end
        return (NoTangent(), NoTangent(), greg)
    end
end

function rrule(
    ::typeof(expect),
    op::AbstractBlock,
    reg_and_circuit::Pair{<:AbstractArrayReg,<:AbstractBlock})
    out = expect(op, reg_and_circuit)
    out,
    function (outδ)
        reg, c = reg_and_circuit
        out = copy(reg) |> c
        goutreg = 2copy(out) |> op
        for b = 1:YaoArrayRegister._asint(nbatch(goutreg))
            viewbatch(goutreg, b).state .*= outδ[b]
        end
        # apply backward rule
        (in, greg), gcircuit = apply_back((out, goutreg), c)
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

function rrule(::Type{ArrayReg{D}}, raw::AbstractArray) where {D}
    ArrayReg{D}(raw), adjy -> (NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::Type{ArrayReg}, raw::AbstractArray)
    ArrayReg(raw), adjy -> (NoTangent(), reshape(adjy.state, size(raw)))
end

function rrule(::Type{BatchedArrayReg{D}}, raw::AbstractArray, nbatch::Int) where {D}
    BatchedArrayReg{D}(raw, nbatch), adjy -> (NoTangent(), reshape(adjy.state, size(raw)), NoTangent())
end

function rrule(::Type{BatchedArrayReg}, raw::AbstractArray, nbatch::Int)
    BatchedArrayReg(raw, nbatch), adjy -> (NoTangent(), reshape(adjy.state, size(raw)), NoTangent())
end

function rrule(::typeof(copy), reg::AbstractArrayReg)
    copy(reg), adjy -> (NoTangent(), adjy)
end

for (BT, BLOCKS) in [(:Add, :(outδ.list)) (:ChainBlock, :(outδ.blocks))]
    @eval function rrule(::Type{BT}, source::AbstractVector) where {BT<:$BT}
        out = BT(source)
        out, function (outδ)
            return (NoTangent(), collect($BLOCKS))
        end
    end
    @eval function rrule(::Type{BT}, source::Tuple) where {BT<:$BT}
        out = BT(source)
        out, function (outδ)
            return (NoTangent(), ($BLOCKS...,))
        end
    end
    @eval function rrule(::Type{BT}, args::AbstractBlock...) where {BT<:$BT}
        out = BT(args...)
        out, function (outδ)
            return (NoTangent(), $BLOCKS...)
        end
    end
end

rrule(::typeof(state), reg::AbstractArrayReg{D,T}) where {D,T} =
    state(reg), adjy -> (NoTangent(), _match_type(reg, _totype(T, adjy)))
rrule(::typeof(statevec), reg::AbstractArrayReg{D,T}) where {D,T} =
    statevec(reg), adjy -> (NoTangent(), _match_type(reg, _totype(T, adjy)))
rrule(::typeof(state), reg::AdjointArrayReg{D,T}) where {D,T} =
    state(reg), adjy -> (NoTangent(), _match_type(parent(reg), _totype(T, adjy)')')
rrule(::typeof(statevec), reg::AdjointArrayReg{D,T}) where {D,T} =
    statevec(reg), adjy -> (NoTangent(), _match_type(parent(reg), _totype(T, adjy)')')
rrule(::typeof(parent), reg::AdjointArrayReg) = parent(reg), adjy -> (NoTangent(), adjy')
rrule(::typeof(Base.adjoint), reg::AbstractArrayReg) =
    Base.adjoint(reg), adjy -> (NoTangent(), parent(adjy))

_totype(::Type{T}, x::AbstractThunk) where {T} = _totype(T, unthunk(x))
_totype(::Type{T}, x::AbstractArray{T}) where {T} = x
_totype(::Type{T}, x::AbstractArray{T2}) where {T,T2} = convert.(T, x)
_match_type(::ArrayReg{D}, mat) where D = ArrayReg{D}(mat)
_match_type(r::BatchedArrayReg{D}, mat) where D = BatchedArrayReg{D}(mat, r.nbatch)

@non_differentiable nparameters(::Any)
@non_differentiable zero_state(args...)
@non_differentiable rand_state(args...)
@non_differentiable uniform_state(args...)
@non_differentiable product_state(args...)
