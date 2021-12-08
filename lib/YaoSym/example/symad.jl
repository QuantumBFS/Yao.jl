using YaoExtensions, Yao, YaoSym

function sym_variational_circuit(nbit, nlayer; pairs = pair_ring(nbit), entangler = cnot)
    circuit = chain(nbit)
    k = 0
    genθ() = (k += 1; Basic(Symbol(:θ, k)))

    ent = chain(nbit, entangler(nbit, i, j) for (i, j) in pairs)
    has_param = nparameters(ent) != 0
    for i in 1:(nlayer+1)
        i != 1 && push!(circuit, has_param ? deepcopy(ent) : ent)
        r = chain(nbit)
        for j in 1:nbit
            ci =
                i == 1 ? (i == nlayer + 1 ? Rx(genθ()) : chain(Rx(genθ()), Rz(genθ()))) :
                (
                    i == nlayer + 1 ? chain(Rz(genθ()), Rx(genθ())) :
                    chain(Rz(genθ()), Rx(genθ()), Rz(genθ()))
                )
            push!(r, put(nbit, j => ci))
        end
        push!(circuit, r)
    end
    circuit
end

circ = sym_variational_circuit(2, 1)

reg = ArrayReg(Basic, bit"00") => circ
op = put(2, 2 => Z)
ex = expect'(op, reg)[2]
params = randn(nparameters(circ))
assign = Dict(zip(parameters(circ), params))
ex2 = map(x -> ComplexF64(subs(x, assign...)), ex)
circ2 = variational_circuit(2, 1, pair_ring(2); mode = :Merged)
dispatch!(circ2, params)
real(ex2) ≈ real(expect'(op, ArrayReg(bit"00") => circ2)[2])
