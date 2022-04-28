using Yao
using SymEngine

shor(E) = chain(9,
    # encode circuit
    cnot(1, 4), cnot(1, 7),
    put(1=>H), put(4=>H), put(7=>H),
    cnot(1,2), cnot(1,3), cnot(4,5), cnot(4,6), cnot(7,8), cnot(7,9),
    E, # the error
    # decode circuit
    cnot(1,2), cnot(1,3), cnot((2, 3), 1),
    cnot(4,5), cnot(4,6), cnot((5, 6), 4),
    cnot(7,8), cnot(7,9), cnot((8, 9), 7),
    put(1=>H), put(4=>H), put(7=>H), cnot(1, 4), cnot(1, 7), cnot((4, 7), 1)
)

@vars α β
s = α * ket"0" + β * ket"1" |> append_qudits!(8)
E = kron(1=>X, 2=>Z, 3=>Z, 4=>X, 5=>Z, 6=>Z, 7=>X, 8=>Z, 9=>Z);
s |> shor(E) |> expand

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

