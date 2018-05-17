using QuCircuit

function entangler(n)
    seq = []
    for i = 1:n
        push!(seq, X(i) |> C(i % n + 1))
    end
    compose(seq)(n)
end

function circuit(n, nlayer)
    first_layer = chain(rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll
    layer = chain(rot(:Z), rot(:X), rot(:Z)) |> cache(2, recursive=true) |> roll

    seq = []
    push!(seq, first_layer(n))
    for i = 1:nlayer
        push!(seq, cache(entangler(n)))
        push!(seq, layer(n))
    end
    chain(seq...)
end

import Base: run

function run(circuit::AbstractBlock, params::Vector, signal::Int=3)
    psi = zero_state(nqubit(circuit))
    dispatch!(psi, params)
    circuit(psi)
end
