for F in [:expect, :fidelity, :operator_fidelity]
    @eval Base.adjoint(::typeof($F)) = Adjoint($F)
    @eval Base.show(io::IO, ::Adjoint{Any,typeof($F)}) = print(io, "$($F)'")
    @eval Base.show(io::IO, ::MIME"text/plain", ::Adjoint{Any,typeof($F)}) =
        print(io, "$($F)'")
end

function _backcirc!(reg, out, outδ)
    if reg isa Pair
        (_, inδ), paramsδ = apply_back((out, outδ), reg.second)
        return regscale!(inδ, 0.5) => paramsδ
    else
        return regscale!(outδ, 0.5)
    end
end
#_merge!(p1::Pair, p2::Pair) = regadd!(p1.first, p2.first)=>(p1.second .+ p2.second)
#_merge!(p1::AbstractArrayReg, p2::AbstractArrayReg) = regadd!(p1, p2)
_double!(p1::Pair) = regscale!(p1.first, 2)=>(p1.second .*= 2)
_double!(p1::AbstractArrayReg) = regscale!(p1, 2)
function (::Adjoint{Any,typeof(expect)})(op::AbstractBlock, reg_or_circuit)
    out = _eval(reg_or_circuit)
    outδ = apply(out, op)
    return _double!(_backcirc!(reg_or_circuit, out, outδ))
end
function (::Adjoint{Any,typeof(expect)})(op::AbstractBlock, left, right)
    los, ros = _eval(left; cp=true), _eval(right)
    # left branch
    loδ = apply(ros, op)
    g1 = _backcirc!(left, los, loδ)
    # right branch
    conj!(los.state)
    roδ = apply!(los, op')
    conj!(roδ.state)
    g2 = _backcirc!(right, ros, roδ)
    return g1, g2
end

YaoAPI.fidelity(p1, p2) = fidelity(_eval(p1), _eval(p2))

function (::Adjoint{Any,typeof(fidelity)})(
    reg1::Union{AbstractArrayReg,Pair{<:AbstractArrayReg,<:AbstractBlock}},
    reg2::Union{AbstractArrayReg,Pair{<:AbstractArrayReg,<:AbstractBlock}},
)
    fidelity_g(reg1, reg2)
end

function fidelity_g(
    reg1::Union{AbstractArrayReg,Pair{<:AbstractArrayReg,<:AbstractBlock}},
    reg2::Union{AbstractArrayReg,Pair{<:AbstractArrayReg,<:AbstractBlock}},
)
    out1, out2 = _eval(reg1), _eval(reg2)
    if nremain(out1) != 0
        throw(
            ArgumentError(
                "The gradient of registers with environment is not implemented yet.
However, back propagating over a focused register is possible,
please file an issue if you really need this feature.",
            ),
        )
    end
    overlap = out1' * out2
    out1δ = copy(out2)
    regscale!.(viewbatch.(Ref(out1δ), 1:length(overlap)), conj.(overlap) ./ abs.(overlap))
    out2δ = copy(out1)
    regscale!.(viewbatch.(Ref(out2δ), 1:length(overlap)), overlap ./ abs.(overlap))
    return _backcirc!(reg1, out1, out1δ), _backcirc!(reg2, out2, out2δ)
end

function (::Adjoint{Any,typeof(operator_fidelity)})(b1::AbstractBlock, b2::AbstractBlock)
    operator_fidelity_g(b1, b2)
end

function operator_fidelity_g(b1::AbstractBlock, b2::AbstractBlock)
    U1 = mat(b1)
    U2 = mat(b2)
    s = sum(conj(U1) .* U2)
    adjs = conj(s) / abs(s) / size(U1, 1)
    adjm1 = U2 * adjs
    adjm2 = U1 * conj(adjs)
    mat_back(b1, adjm1), mat_back(b2, adjm2)
end
