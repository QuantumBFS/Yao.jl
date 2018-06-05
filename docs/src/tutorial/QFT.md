# Quantum Fourier Transform

```@example QFT
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
