using QuCircuit
include("QCBM.jl")

const nlayers = 10
const nbit = 9
const maxiter = 10
const learning_rate = 0.1

const kernel = RBFKernel(nbit, [2.0], false)
const params = reverse(vec(readdlm("theta-cl-bs.dat")))
const target = readdlm("wave_complex.dat")[:, 1] + im * readdlm("wave_complex.dat")[:, 2]

cnot_pair = [
    (2, 8),
    # (3, 9),
    # (5, 8),
    # (6, 4),
    # (7, 1),
    # (7, 4),
    # (7, 8),
    # (9, 6),
]

function entangler(n, pairs)
    seq = []
    for (c, uc) in pairs
        push!(seq, X(uc) |> C(c))
    end
    compose(seq)(n)
end


layer1 = roll(nbit, chain(rot(:X), rot(:Z)))
layers = MatrixBlock[]
push!(layers, layer1)
layer = roll(chain(rot(:Z), rot(:X), rot(:Z)) |> cache(2, recursive=true))

for i = 1:9
    push!(layers, cache(entangler(nbit, cnot_pair)))
    push!(layers, layer(nbit))
end

push!(layers, roll(nbit, chain(rot(:Z), rot(:X))))
circuit = chain(layers...)
dispatch!(circuit, params)
display(vec(state(circuit(zero_state(nbit))))[1:20])

# dispatch!(layer(9)(zero_state(nbit)), params)
# display(state(layer1(zero_state(nbit))))
