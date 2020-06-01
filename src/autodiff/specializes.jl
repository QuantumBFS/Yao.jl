for F in [:expect, :fidelity, :operator_fidelity]
    @eval Base.adjoint(::typeof($F)) = Adjoint($F)
    @eval Base.show(io::IO, ::Adjoint{Any,typeof($F)}) = print(io, "$($F)'")
    @eval Base.show(io::IO, ::MIME"text/plain", ::Adjoint{Any,typeof($F)}) = print(io, "$($F)'")
end

function (::Adjoint{Any,typeof(expect)})(op::AbstractBlock, reg_or_circuit)
    expect_g(op, reg_or_circuit)
end

function expect_g(op::AbstractBlock, circuit::Pair{<:ArrayReg,<:AbstractBlock})
    reg, c = circuit
    out = copy(reg) |> c
    outδ = copy(out) |> op
    (in, inδ), paramsδ = apply_back((out, outδ), c)
    return inδ => paramsδ .* 2
end

function expect_g(op::AbstractBlock, reg::ArrayReg)
    copy(reg) |> op
end

_eval(p::Pair{<:AbstractRegister,<:AbstractBlock}) = copy(p.first) |> p.second
_eval(reg::AbstractRegister) = reg
YaoBase.fidelity(p1, p2) = fidelity(_eval(p1), _eval(p2))

function (::Adjoint{Any,typeof(fidelity)})(
    reg1::Union{ArrayReg,Pair{<:ArrayReg,<:AbstractBlock}},
    reg2::Union{ArrayReg,Pair{<:ArrayReg,<:AbstractBlock}},
    )
    fidelity_g(reg1, reg2)
end

function fidelity_g(
    reg1::Union{ArrayReg,Pair{<:ArrayReg,<:AbstractBlock}},
    reg2::Union{ArrayReg,Pair{<:ArrayReg,<:AbstractBlock}},
    )
    if reg1 isa Pair
        in1, c1 = reg1
        out1 = copy(in1) |> c1
    else
        out1 = reg1
    end

    if reg2 isa Pair
        in2, c2 = reg2
        out2 = copy(in2) |> c2
    else
        out2 = reg2
    end
    if nremain(out1) != 0
        throw(ArgumentError("The gradient of registers with environment is not implemented yet.
        However, back propagating over a focused register is possible,
        please file an issue if you really need this feature."))
    end
    overlap = out1' * out2

    out1δ = copy(out2)
    regscale!.(out1δ, conj.(overlap) ./ 2 ./ abs.(overlap))
    out2δ = copy(out1)
    regscale!.(out2δ, overlap ./ 2 ./ abs.(overlap))

    if reg1 isa Pair
        (_, in1δ), params1δ = apply_back((out1, out1δ), c1)
        res1 = in1δ => params1δ .* 2
    else
        res1 = out1δ
    end

    if reg2 isa Pair
        (_, in2δ), params2δ = apply_back((out2, out2δ), c2)
        res2 = in2δ => params2δ .* 2
    else
        res2 = out2δ
    end

    return res1, res2
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
