# Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit

First, you have to use this package in Julia.

```@example GHZ
using QuCircuit
```

Then let's define the oracle, it is a function of the number of qubits.
The whole oracle looks like this:


```@example GHZ
circuit(num_bits) = sequence(
    X(num_bits, 1),
    H(num_bits, 2:num_bits),
    X(1) |> C(num_bits, 2),
    X(3) |> C(num_bits, 4),
    X(1) |> C(num_bits, 3),
    X(3) |> C(num_bits, 4),
    H(num_bits, 1:num_bits),
)
```

After we have an circuit, we can construct a quantum register, and
input it into the oracle. You will then receive this register after
processing it.

```@example GHZ
reg = zero_state(4)

reg |> circuit(4)
reg
```

Let's check the output:

```@example GHZ
state(reg)
```

We have a GHZ state here, try to measure the first qubit

```@example GHZ
reg |> measure(1)
state(reg)
```

GHZ state will collapse to ``|0000\rangle`` or ``|1111\rangle`` due to entanglement!
