# # Riemannian gradient flow optimizer

# In this tutorial we will present the Riemannian gradient descent algorithm described in [Miao and Barthel (2021)](https://arxiv.org/pdf/2108.13401.pdf)
# and [Wiersema and Killoran (2022)](https://arxiv.org/pdf/2202.06976.pdf)
# As opposed to most standard optimization algorithms that optimize parameters of variational quantum circuits,
# this algorithm optimizes a function directly over the special unitary group by following the gradient flow over the manifold.
# Let's start by importing the necessary packages.

using Yao, Yao.EasyBuild, Plots, Random
using KrylovKit: eigsolve

# Variational quantum eigensolver (VQE) is one of the most celebrated near-term quantum algorithms.
# In the usual setting, VQE tries to reach the ground state by minimizing the energy cost function
# ```math
# \mathcal{L}(\theta) = \text{Tr}\{HU(\theta)\rho_0U^\dagger(\theta)\},
# ```
# with respect to parameters ``\theta`` which parameterize a quantum circuit ``U(\theta)``, 
# where ``\rho_0 = |\psi_0\rangle\langle\psi_0|`` is some initial state and ``H`` the Hamiltonian whose ground state we want to approximate.
# We can solve the optimization problem ``\text{min}_\theta\mathcal{L}(\theta)`` by following 
# the direction of the steepest descent in parameter space which is given by the gradient of the cost function,
# i.e. by considering the following gradient flow
# ```math
# \dot{\theta} = -\text{grad}\mathcal{L}(\theta).
# ```
# Discretizing the equation above, we recover the well-known gradient descent algorithm
# ```math
# \theta_{k + 1} = \theta_k - \alpha\text{grad}\mathcal{L}(\theta),
# ```
# where ``\alpha`` is the learning rate.
# Let's demonstrate it on the example of finding the ground state of the transverse field Ising model.

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

Plots.plot(history, legend=false)
Plots.plot!(1:100, [w[1] for i=1:100])
xlabel!("steps")
ylabel!("energy")

# Let's now consider the energy cost function directly over the special unitary group ``\mathcal{L}: \text{SU}(2^n) \rightarrow \mathbb{R}``
# ```math
# \mathcal{L}(U) = \text{Tr}\{HU\rho_0U^\dagger\}.
# ```
# To minimize the cost function we can follow the Riemannian gradient flow defined through the following differential equation
# ```math
# \dot{U} = -\text{grad}\mathcal{L}(U) = [U\rho_0U^\dagger, H]U.
# ```
# Discretizing the flow we get the following recursive update rule
# ```math
# U_{k + 1} = \exp\{\alpha[U_k\rho_0U^\dagger_k, H]\}U_k = \exp\{\alpha[\rho_k, H]\}U_k,
# ```
# where ``\alpha`` is the appropriate learning rate and ``U_0 = I``.


# We can expand the commutator in the exponent in the basis of Pauli strings ``P^j``
# ```math
# [\rho_k, H] = \frac{1}{2^n}\sum_{j = 1}^{4^n - 1}\omega^j_kP^j,
# ```
# where
# ```math
# \omega^j_k = \text{Tr}\{[\rho_k, H]P^j\} = \text{Tr}\{[H, P^j]\rho_k\} = \langle[H, P^j]\rangle_{\rho_k}.
# ```
# It turns out that ``\omega^j_k`` can easily be evaluated with the help of a parameter shift rule
# ```math
# \omega^j_k = \langle[H, P^j]\rangle_{\rho_k} = -i\langle V^\dagger_j(\pi/4)HV_j(\pi/4) - V^\dagger_j(-\pi/4)HV_j(-\pi/4)\rangle_{\rho_k},
# ```
# where ``V_j(t) = \exp\{-itP^j\}``.

# Next, we write a function for generation of 2-local Pauli operators.
# We will restrict the Riemannian gradient to this subspace of the Lie algebra since otherwise the number 
# of parameters to calculate would be ``4^8 - 1 = 65535`` which is too much for a reasonable runtime of the algorithm. 

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

# Next we write functions for calculating the expansion coefficients and a single optimization step.
# We will absorb the factor of ``1/2^n`` into the learning rate.

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
      
# Finally, let's try it out.
# We initialize the state ``|0\rangle`` and apply several optimization steps.

# ```julia
# circuit = chain(n)
# pauli_strings = generate_2local_pauli_strings(n)
# history = Float64[]

# for i=1:100
#     cost = step_and_cost!(n, circuit, h, 0.01, pauli_strings)
#     push!(history, cost)
# end

# Plots.plot(history, legend=false)
# Plots.plot!(1:100, [w[1] for i=1:100])
# xlabel!("steps")
# ylabel!("energy")
# ```

# ```@raw html
# <img src="/assets/images/Riemannian.png" alt="Riemannian gradient flow" width="600"/>
# ```
# When we compare the final states achieved with the Riemannian gradient flow 
# optimizer and with the standard VQE we can notice that the former has lower quality.
# This is because the Riemannian gradient flow optimizer has only a local view of the cost landscape
# while VQE can access these directions since the ansatz we used is universal.
# However, if we were able to calculate all of the ``4^n - 1`` projections, 
# Riemannian gradient flow optimizer would be guaranteed to converge given the appropriate learning rate!
