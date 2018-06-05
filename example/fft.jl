function IQFT(n::Int)
    circuit = []
    for i = n:-1:1
        push!(circuit, kron(n, k=>H))
        for j = i-1:-1:1
            k = i - j + 1
            push!(circuit, control(n, [j, ], shift(2π/(1<<k)), i))
        end
    end
    chain(circuit)
end

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
