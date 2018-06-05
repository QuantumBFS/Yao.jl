# Quantum Fourier Transform

```@example QFT
function QFT(n::Int)
    circuit = []
    for i = 1:n
        push!(circuit, kron(n, k=>H))
        for j = i+1:n
            k = j - i + 1
            push!(circuit, control(n, [i, ], shift(-2π/(1<<k)), j))
        end
    end
    chain(circuit)
end
```
