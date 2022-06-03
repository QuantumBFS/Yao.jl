# # Riemannian gradient-flow optimization

# In this tutorial we will present the Riemannian gradient descent algorithm described in [Wiersema and Killoran (2022)](https://arxiv.org/pdf/2202.06976.pdf).

using Yao, Yao.EasyBuild
using KrylovKit: eigsolve

# Utility function for generation of Pauli operators

function generate_paulis(n)
    ans = []
    for i=1:4^n-1
        tmp = i
        pauli_string = []
        for j=1:n
            if tmp % 4 == 0
                push!(pauli_string, j => I2)
            elseif tmp % 4 == 1
                push!(pauli_string, j => X)
            elseif tmp % 4 == 2
                push!(pauli_string, j => Y)
            else
                push!(pauli_string, j => Z)
            end
            tmp ÷= 4
        end
        push!(ans, kron(n, pauli_string...))
    end
    ans
end
  
# Calculating expansion coefficients
  
function calculate_omegas(n, reg, H_prob)
    paulis = generate_paulis(n)
    omegas = []
    for P in paulis
        push!(omegas, 0.5 * real(expect(H_prob, reg => time_evolve(P, π/4)) - expect(H_prob, reg => time_evolve(P, -π/4))))
    end
    omegas, paulis
end
    
# Function implementing a single optimization step

function step_and_cost(n, circuit, H_prob, α)
    omegas, paulis = calculate_omegas(n, zero_state(n) |> circuit, H_prob)

    for (ω, P) in zip(omegas, paulis)
        if abs(ω) > 1e-6
            append!(circuit, chain(n, time_evolve(P, -ω * α)))
        end
    end

    real(expect(H_prob, zero_state(n) => circuit))
end
      
# Finally, let's try it out

n = 2;
H_prob = -kron(n, 1 => X) - kron(n, 2=>Z) - kron(n, 1=>Y, 2=>X);
w, v = eigsolve(mat(H_prob), 1, :SR, ishermitian=true);
w[1]

circuit = chain(n, [put(n, 1 => Rx(0.1)), 
                    put(n, 2 => Ry(0.5)),
                    cnot(n, 1, 2),
                    put(n, 1 => Ry(0.6))]);

expect(H_prob, zero_state(n) => circuit)

for i=1:5
    cost = step_and_cost(n, circuit, H_prob, 0.1)
    println(cost)
end
