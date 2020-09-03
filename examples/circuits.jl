using YaoExtensions, YaoPlots
using Compose, Cairo

_save(str) = PNG(joinpath(@__DIR__, str))

# qft circuit
vizcircuit(qft_circuit(5)) |> _save("qft.png")

# variational circuit
vizcircuit(variational_circuit(5)) |> _save("variational.png")
# vizcircuit(variational_circuit(5; mode=:Merged))

# general U4 gate
vizcircuit(general_U4()) |> _save("u4.png")

# quantum supremacy circuit
vizcircuit(rand_supremacy2d(2, 2, 8)) |> _save("supremacy2d.png")

# google 52 qubit
vizcircuit(rand_google53(10)) |> _save("google53.png")

# control blocks
vizcircuit(chain(control(5, (2,-3), 4=>X), control(5, (-4, -2), 1=>Z))) |> _save("controls.png")

# controlled kron
control(4, 2, (1, 3)=>kron(X, X)) |> vizcircuit |> _save("cxx.png")
