module GHZ

export circuit
using QuCircuit

circuit(n) = sequence(
    X(n, 1),
    H(n, 2:n),
    X(1) |> C(n, 2),
    X(3) |> C(n, 4),
    X(1) |> C(n, 3),
    X(3) |> C(n, 4),
    H(n, 1:n),
)

end
