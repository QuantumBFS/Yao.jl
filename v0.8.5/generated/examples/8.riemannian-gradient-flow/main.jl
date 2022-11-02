using Yao, Yao.EasyBuild, Plots, Random
using KrylovKit: eigsolve

n = 8
h = transverse_ising(n, 1.0)
w, v = eigsolve(mat(h), 1, :SR, ishermitian=true)

Random.seed!(0)
circuit = dispatch!(variational_circuit(n, 100), :random);
history = Float64[]
for i in 1:100
    _, grad = expect'(h, zero_state(n) => circuit)
    dispatch!(-, circuit, 0.01 * grad)
    push!(history, real.(expect(h, zero_state(n)=>circuit)))
end

plot(history, legend=false)
plot!(1:100, [w[1] for i=1:100])
xlabel!("steps")
ylabel!("energy")

function generate_2local_pauli_strings(n)
    pauli_strings = []
    for i = 1:n
        push!(pauli_strings, kron(n, i => X))
        push!(pauli_strings, kron(n, i => Y))
        push!(pauli_strings, kron(n, i => Z))
    end
    for i = 1:n-1
        for j = i+1:n
            for P1 in [X, Y, Z]
                for P2 in [X, Y, Z]
                    push!(pauli_strings, kron(n, i => P1, j => P2))
                end
            end
        end
    end
    pauli_strings
end;

function calculate_omegas(n, reg, h, pauli_strings)
    iω = []
    for P in pauli_strings
        push!(iω, real(expect(h, reg => time_evolve(P, π/4)) - expect(h, reg => time_evolve(P, -π/4))))
    end
    iω
end;

function step_and_cost!(n, circuit, h, α, pauli_strings)
    iω = calculate_omegas(n, zero_state(n) |> circuit, h, pauli_strings)

    for (iωʲ, P) in zip(iω, pauli_strings)
        if abs(iωʲ) > 1e-6 # we will only keep the ones that actually contribute
            append!(circuit, chain(n, time_evolve(P, -α * iωʲ)))
        end
    end

    real(expect(h, zero_state(n) => circuit))
end;

circuit = chain(n)
pauli_strings = generate_2local_pauli_strings(n)
history = Float64[]

for i=1:100
    cost = step_and_cost!(n, circuit, h, 0.01, pauli_strings)
    push!(history, cost)
end

plot(history, legend=false)
plot!(1:100, [w[1] for i=1:100])
xlabel!("steps")
ylabel!("energy")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

