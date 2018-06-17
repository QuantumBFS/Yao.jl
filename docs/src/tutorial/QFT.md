# Quantum Fourier Transform
![ghz](../assets/figures/qft.png)

```@example QFT
using Yao

function QFT(n::Int)
    circuit = chain(n)
    for i = 1:n - 1
        push!(circuit, i=>H)
        g = chain(
            control([i, ], j=>shift(-2π/(1<< (j - i + 1))))
            for j = i+1:n
        )
        push!(circuit, g)
    end
    push!(circuit, n=>H)
end

QFT(5)
```

In Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total
number of qubits of `chain`, then it will return a function that requires an input of an integer.

If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.

```julia
chain(4, repeat(1=>X), kron(2=>Y))
```
