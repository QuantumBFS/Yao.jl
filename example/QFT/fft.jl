function IQFT(n::Int)
    circuit = []
    for i = n:-1:1
        push!(circuit, kron(n, i=>H))
        for j = i-1:-1:1
            k = i - j + 1
            push!(circuit, control(n, [j, ], shift(2π/(1<<k)), i))
        end
    end
    chain(circuit)
end

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

@compose 3 begin
    1 => X
    @control 2 1=>X
    3 => Y
end
