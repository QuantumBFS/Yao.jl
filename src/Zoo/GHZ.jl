module GHZ

export circuit
using QuCircuit

circuit(n) = compose(
    X(1),
    H(2:n),
    X(1) |> C(2),
    X(3) |> C(4),
    X(1) |> C(3),
    X(3) |> C(4),
    H(1:n),
)

end
