export cphase, ISWAP, SqrtX, SqrtY, SqrtW
export ISWAPGate, SqrtXGate, SqrtYGate, SqrtWGate

cphase(nbits, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))
const CPhaseGate{N, T} = ControlBlock{N,<:ShiftGate{T},<:Any}

@const_gate ISWAP = PermMatrix([1,3,2,4], [1,1.0im,1.0im,1])
@const_gate SqrtX = [0.5+0.5im 0.5-0.5im; 0.5-0.5im 0.5+0.5im]
@const_gate SqrtY = [0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]
# √W is a non-Clifford gate
@const_gate SqrtW = mat(rot((X+Y)/sqrt(2), π/2))


function singlet_block(nbit::Int, i::Int, j::Int)
    unit = chain(nbit)
    push!(unit, put(nbit, i=>chain(X, H)))
    push!(unit, control(nbit, -i, j=>X))
end

singlet_block() = singlet_block(2,1,2)

"""Identity block"""
eyeblock(nbits::Int) = put(nbits, 1=>I2)
