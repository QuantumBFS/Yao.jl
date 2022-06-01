using Yao

circuit = chain(
    4,
    put(1=>X),
    repeat(H, 2:4),
    control(2, 1=>X),
    control(4, 3=>X),
    control(3, 1=>X),
    control(4, 3=>X),
    repeat(H, 1:4),
)

put(4, 1=>X)

put(4, (1, 2)=>swap(2, 1, 2))

put(1=>X)

put(1=>X)(4)

repeat(H, 2:4)

control(4, 2, 1=>X)

control(2, 1=>X)

circuit = chain(
    4,
    put(1=>X),
    repeat(H, 2:4),
    control(2, 1=>X),
    control(4, 3=>X),
    control(3, 1=>X),
    control(4, 3=>X),
    repeat(H, 1:4),
)

typeof(circuit)

zero_state(4)

ArrayReg(bit"0000")

apply!(zero_state(4), circuit)

results = zero_state(4) |> circuit |> r->measure(r, nshots=1000)

using StatsBase, Plots

hist = fit(Histogram, Int.(results), 0:16)
bar(hist.edges[1] .- 0.5, hist.weights, legend=:none)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

