# # Riemannian gradient-flow optimizer

# In this tutorial we will present the Riemannian gradient descent algorithm described in [Wiersema and Killoran (2022)](https://arxiv.org/pdf/2202.06976.pdf).
# As opposed to most standard optimization algorithms that optimize parameters of variational quantum circuits,
# this algorithm optimizes a function directly over the special unitary group by following the gradient-flow over the manifold.

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
end;
  
# Calculating expansion coefficients
  
function calculate_omegas(n, reg, H_prob)
    paulis = generate_paulis(n)
    omegas = []
    for P in paulis
        push!(omegas, 0.5 * real(expect(H_prob, reg => time_evolve(P, π/4)) - expect(H_prob, reg => time_evolve(P, -π/4))))
    end
    omegas, paulis
end;
    
# ## Algorithm description

# Let us consider the VQE cost function directly over the special unitary group ``\mathcal{L}: \text{SU}(N) \rightarrow \mathbb{R}``
# ```math
# \mathcal{L}(U) = \text{Tr}\{HU\rho_0U^\dagger\}.
# ```
# To optimize the cost function we can follow the Riemannian gradient-flow defined through the following differential equation
# ```math
# \dot{U} = \text{grad}\mathcal{L}(U) = [U\rho_0U^\dagger, H]U.
# ```

# Discretizing the flow we get the following
# ```math
# U_{k + 1} = \exp\{\alpha[U_k\rho_0U^\dagger_k, H]\}U_k,
# ```
# where ``\alpha`` is appropriate learning rate.
        
# Now let us implement the function for a single optimization step.

function step_and_cost(n, circuit, H_prob, α)
    omegas, paulis = calculate_omegas(n, zero_state(n) |> circuit, H_prob)

    for (ω, P) in zip(omegas, paulis)
        if abs(ω) > 1e-6
            append!(circuit, chain(n, time_evolve(P, -ω * α)))
        end
    end

    real(expect(H_prob, zero_state(n) => circuit))
end;
      
# Finally, let us try it out.

n = 2
H_prob = -kron(n, 1 => X) - kron(n, 2=>Z) - kron(n, 1=>Y, 2=>X)
w, v = eigsolve(mat(H_prob), 1, :SR, ishermitian=true)
w[1]
 
# We initialize the state and apply several optimization steps
            
circuit = chain(n, [put(n, 1 => Rx(0.1)), 
                    put(n, 2 => Ry(0.5)),
                    cnot(n, 1, 2),
                    put(n, 1 => Ry(0.6))]);

for i=1:10
    cost = step_and_cost(n, circuit, H_prob, 0.1)
    println(cost)
end
