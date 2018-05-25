# Prepare Greenberger–Horne–Zeilinger state with Quantum Circuit

First, you have to use this package in Julia.

```@example GHZ
using QuCircuit
```

Then let's define the oracle, it is a function of the number of qubits.
The whole oracle looks like this:


```@example GHZ
circuit(n) = compose(
    X(1),
    H(2:n),
    X(1) |> C(2),
    X(3) |> C(4),
    X(1) |> C(3),
    X(3) |> C(4),
    H(1:n),
)
```

After we have an circuit, we can construct a quantum register, and
input it into the oracle. You will then receive this register after
processing it.

```@example GHZ
reg = register(bit"0000")
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
