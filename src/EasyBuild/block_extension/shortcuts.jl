export cphase, ISWAP, SqrtX, SqrtY, SqrtW
export ISWAPGate, SqrtXGate, SqrtYGate, SqrtWGate

const CPhaseGate{N, T} = ControlBlock{N,<:ShiftGate{T},<:Any}

@const_gate ISWAP = PermMatrix([1,3,2,4], [1,1.0im,1.0im,1])
@const_gate SqrtX = [0.5+0.5im 0.5-0.5im; 0.5-0.5im 0.5+0.5im]
@const_gate SqrtY = [0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]
# √W is a non-Clifford gate
@const_gate SqrtW = mat(rot((X+Y)/sqrt(2), π/2))

singlet_block() = chain(put(2, 1=>chain(X, H)), control(2, -1, 2=>X))

"""
    fsim_block(θ::Real, ϕ::Real)

The circuit representation of FSim gate.
"""
function fsim_block(θ::Real, ϕ::Real)
    if θ ≈ π/2
        return cphase(2,2,1,-ϕ)*SWAP*rot(kron(Z,Z), -π/2)*put(2,1=>phase(-π/4))
    else
        return cphase(2,2,1,-ϕ)*rot(SWAP,2*θ)*rot(kron(Z,Z), -θ)*put(2,1=>phase(θ/2))
    end
end