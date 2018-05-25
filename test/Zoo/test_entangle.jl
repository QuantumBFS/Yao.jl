using QuCircuit
include("QCBM.jl")

cnot_pair = [
    (1, 7),
    (2, 8),
    (4, 7),
    (5, 3),
    (6, 0),
    (6, 3),
    (6, 7),
    (8, 5),
]

cnot_pair = map(x->(x[1]+1, x[2]+1), cnot_pair)

function entangler(n, pairs)
    seq = []
    for (c, uc) in pairs
        push!(seq, X(uc) |> C(c))
    end
    compose(seq)(n)
end

st = zeros(Complex128, 1<<9)
st[end] = 1
reg = register(st)
entangler(9, cnot_pair)(reg)
display(state(reg))
