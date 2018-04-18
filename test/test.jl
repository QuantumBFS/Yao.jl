using TensorOperations
import QuCircuit: X, Y, Z, H, CNOT, gate, Gate, apply!, register
import QuCircuit.Routine: OOO, Rand

reg = register(Rand, 4)
t_reg = copy(reg)
apply!(gate(X), reg, 2)

PX = [0 1;1 0]
I = [1 0;0 1]

function permute_apply(state, OP)
    state = reshape(state, 2, 2, 2, 2)
    t = permutedims(state, [2, 1, 3, 4])
    t = reshape(t, 2, 8)
    s1 = reshape(OP * t, 2, 2, 2, 2)
    t = permutedims(s1, [2, 1, 3, 4])
    return reshape(t, 16)
end

function kron_apply(state, OP)
    kron(kron(kron(I, I), OP), I) * reshape(state, 16)
end

function tensor_apply(state, OP)
    state = reshape(state, 2, 2, 2, 2)
    @tensor s3[1, i, 3, 4] := state[1, 2, 3, 4] * OP[2, i]
    return reshape(s3, 16)
end

# state = t_reg.state

# s2 = kron(kron(kron(I, I), PX), I) * reshape(state, 16)
# @tensor s3[1, i, 3, 4] := state[1, 2, 3, 4] * PX[2, i]
# s3 = reshape(s3, 16)