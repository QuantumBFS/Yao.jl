using QuCircuit
using Compat.Test

num_bits = 4
ghz_state = zeros(Complex128, 1<<num_bits)
ghz_state[1] = 1 / sqrt(2)
ghz_state[end] = -1 / sqrt(2)

psi = zero_state(4)

circuit = sequence(
    X(num_bits, 1),
    H(num_bits, 2:num_bits),
    X(1) |> C(num_bits, 2),
    X(3) |> C(num_bits, 4),
    X(1) |> C(num_bits, 3),
    X(3) |> C(num_bits, 4),
    H(num_bits, 1:num_bits),
)

for info in psi >> circuit
    println("iblock=", info["iblock"])
    println("current=", info["current"])
    println("next=", info["next"])
end
@test state(psi) ≈ ghz_state
