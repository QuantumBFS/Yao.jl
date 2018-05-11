using QuCircuit
using Compat.Test

num_bits = 4
ghz_state = zeros(Complex128, 1<<num_bits)
ghz_state[1] = 1 / sqrt(2)
ghz_state[end] = -1 / sqrt(2)

psi = zero_state(4)

circuit(n) = compose(
    X(1),
    H(2:n),
    X(1) |> C(2),
    X(3) |> C(4),
    X(1) |> C(3),
    X(3) |> C(4),
    H(1:n),
)

for info in psi >> circuit(4)
    println("iblock=", info["iblock"])
    println("current=", info["current"])
    println("next=", info["next"])
end
@test state(psi) ≈ ghz_state
