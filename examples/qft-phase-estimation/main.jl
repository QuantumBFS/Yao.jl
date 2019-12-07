# # Quantum Fourier Transformation and Phase Estimation

# Let's use Yao first

using Yao

# ## Quantum Fourier Transformation

# The Quantum Fourier Transformation (QFT) circuit is to repeat
# two kinds of blocks repeatly:

# ![qft-circuit](assets/qft.png)

# The basic building block control phase shift gate is defined
# as

# ```math
# R(k)=\begin{bmatrix}
# 1 & 0\\
# 0 & \exp\left(\frac{2\pi i}{2^k}\right)
# \end{bmatrix}
# ```

# Let's define block `A` and block `B`, block `A` is actually
# a control block.

A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))

# Once you construct the blockl you can inspect its matrix using [`mat`](@ref)
# function. Let's construct the circuit in dash box A, and see the matrix of
# ``R_4`` gate.

R4 = A(4, 1)

# If you have read about [preparing GHZ state](@ref example-ghz),
# you probably know that in Yao, we could just leave the number of qubits, and it
# will be evaluated when possible.

R4(5)

# its matrix will be

mat(R4(5))

# Then we repeat this control block over
# and over on different qubits, and put a Hadamard gate
# to `i`th qubit to construct `i`-th `B` block.

B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)

# We need to input the total number of qubits `n` here because we have to iterate
# through from `k`-th location to the last.

# Now, let's construct the circuit by chaining all the `B` blocks together

qft(n) = chain(B(n, k) for k in 1:n)
qft(4)

# ## Wrap QFT to an external block

# In most cases, `function`s are enough to wrap quantum circuits, like `A`
# and `B` we defined above, but sometimes, we need to dispatch specialized
# methods on certain kinds of quantum circuit, or we want to define an external
# block to export, thus, it's useful to be able to wrap circuit to custom blocks.

# First, we define a new type as subtype of [`PrimitiveBlock`](@ref) since we are not
# going to use the subblocks of `QFT`, if you need to use its subblocks, it'd
# be better to define it under [`CompositeBlock`](@ref).

struct QFT{N} <: PrimitiveBlock{N} end
QFT(n::Int) = QFT{n}()

# Now, let's define its circuit

circuit(::QFT{N}) where N = qft(N)

# And forward [`mat`](@ref) to its circuit's matrix

YaoBlocks.mat(::Type{T}, x::QFT) where T = mat(T, circuit(x))

# You may notice, it is a little ugly to print `QFT` at the moment,
# this is because we print the type summary by default, you can define
# your own printing by overloading [`print_block`](@ref)

YaoBlocks.print_block(io::IO, x::QFT{N}) where N = print(io, "QFT($N)")

# Since it is possible to use FFT to simulate the results of QFT (like cheating),
# we could define our custom [`apply!`](@ref) method:

using FFTW, LinearAlgebra

function YaoBlocks.apply!(r::ArrayReg, x::QFT)
    α = sqrt(length(statevec(r)))
    invorder!(r)
    lmul!(α, ifft!(statevec(r)))
    return r
end

# Now let's check if our `apply!` method is correct:

r = rand_state(5)
r1 = r |> copy |> QFT(5)
r2 = r |> copy |> circuit(QFT(5))
r1 ≈ r2

# We can get iQFT (inverse QFT) directly by calling `adjoint`

QFT(5)'

# QFT and iQFT are different from FFT and IFFT in three ways,

# 1. they are different by a factor of ``\sqrt{2^n}`` with ``n`` the number of qubits.
# 2. the [bit numbering](https://quantumbfs.github.io/BitBasis.jl/stable/tutorial/#Conventions-1) will exchange after applying QFT or iQFT.
# 3. due to the convention, QFT is more related to IFFT rather than FFT.

# ## Phase Estimation

# Since we have QFT and iQFT blocks we can then use them to
# realize phase estimation circuit, what we want to realize
# is the following circuit:

# ![phase estimation](assets/phaseest.png)

using Yao

# First we call Hadamard gates repeatly on first `n` qubits.

Hadamards(n) = repeat(H, 1:n)

# Then in dashed box `B`, we have controlled unitaries:

ControlU(n, m, U) = chain(n+m, control(k, n+1:n+m=>matblock(U^(2^(k-1)))) for k in 1:n)

# each of them is a `U` of power ``2^(k-1)``.

# Since we will only apply the qft and Hadamard on first `n` qubits,
# we could use [`Concentrator`](@ref), which creates a context of
# a sub-scope of the qubits.

PE(n, m, U) =
    chain(n+m, # total number of the qubits
        concentrate(Hadamards(n), 1:n), # apply H in local scope
        ControlU(n, m, U),
        concentrate(QFT(n)', 1:n))

# we use the first `n` qubits as the output space to store phase ``ϕ``, and the
# other `m` qubits as the input state which corresponds to an eigenvector of
# oracle matrix `U`.

# The concentrator here uses [`focus!`](@ref) and [`relax!`](@ref) to manage
# a local scope of quantum circuit, and only active the first `n` qubits while applying
# the block inside the concentrator context, and the scope will be [`relax!`](@ref)ed
# back, after the context. This is equivalent to manually [`focus!`](@ref)
# then [`relax!`](@ref)

# fullly activated

r = rand_state(5)

# first 3 qubits activated

focus!(r, 1:3)

# relax back to the original

relax!(r, 1:3)

# In this way, we will be able to apply small operator directly
# on the subset of the qubits.

# Details about the algorithm can be found here:
# [Quantum Phase Estimation Algorithm](ttps://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm)

# Now let's check the results of our phase estimation.


# First we need to set up a unitary with known phase, we set the phase to be
# 0.75, which is `0.75 * 2^3 == 6 == 0b110` .

# # using LinearAlgebra

N, M = 3, 5
P = eigen(rand_unitary(1<<M)).vectors
θ = Int(0b110) / 1<<N
phases = rand(1<<M)
phases[0b010+1] = θ
U = P * Diagonal(exp.(2π * im * phases)) * P'

# and then generate the state ``ψ``

psi = P[:, 3]

# In the phase estimation process, we will feed the state to circuit and measure
# the first `n` qubits processed by iQFT.

r = join(ArrayReg(psi), zero_state(N))
r |> PE(N, M, U)

# Since our phase can be represented by 3 qubits precisely, we only need to measure once

results = measure(r, 1:N; nshots=1)

# Recall that our QFT's bit numbering is reversed, let's reverse it back

using BitBasis
estimated_phase = bfloat(results[]; nbits=N)

# the phase is exactly `0.75`!
