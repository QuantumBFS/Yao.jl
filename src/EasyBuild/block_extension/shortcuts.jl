export ISWAP, SqrtX, SqrtY, SqrtW, singlet_block
export ISWAPGate, SqrtXGate, SqrtYGate, SqrtWGate, CPhaseGate

const CPhaseGate{T} = ControlBlock{<:ShiftGate{T},<:Any}

@const_gate ISWAP = PermMatrix([1,3,2,4], [1,1.0im,1.0im,1])
@const_gate SqrtX = [0.5+0.5im 0.5-0.5im; 0.5-0.5im 0.5+0.5im]
@const_gate SqrtY = [0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]
# √W is a non-Clifford gate
@const_gate SqrtW = mat(rot((X+Y)/sqrt(2), π/2))

"""
    singlet_block(θ::Real, ϕ::Real)

The circuit block for initialzing a singlet state.
"""
singlet_block() = chain(put(2, 1=>chain(X, H)), control(2, -1, 2=>X))

YaoPlots.get_brush_texts(c, ::SqrtWGate) = (c.gatestyles.g, "√W")
YaoPlots.get_brush_texts(c, ::SqrtXGate) = (c.gatestyles.g, "√X")
YaoPlots.get_brush_texts(c, ::SqrtYGate) = (c.gatestyles.g, "√Y")

# Decompose to basic rotation gates for QASM compatibility (differs by global phase)
YaoBlocks.Optimise.to_basictypes(::SqrtXGate) = Rx(Float64(π)/2)
YaoBlocks.Optimise.to_basictypes(::SqrtYGate) = Ry(Float64(π)/2)
YaoBlocks.Optimise.to_basictypes(::SqrtWGate) = chain(Rz(-Float64(π)/4), Rx(Float64(π)/2), Rz(Float64(π)/4))

