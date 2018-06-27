# Quantum Fourier Transform
![ghz](../assets/figures/qft.png)

```@example QFT
using Yao

# Control-R(k) gate in block-A
A(i::Int, j::Int, k::Int) = control([i, ], j=>shift(-2π/(1<<k)))
# block-B
B(n::Int, i::Int) = chain(i==j ? kron(i=>H) : A(j, i, j-i+1) for j = i:n)
QFT(n::Int) = chain(n, B(n, i) for i = 1:n)

# define QFT and IQFT block.
num_bit = 5
qft = QFT(num_bit)
iqft = adjoint(qft)
```

The basic building block - controled phase shift gate is defined as

```math
R(k)=\begin{bmatrix}
1 & 0\\
0 & \exp\left(\frac{2\pi i}{2^k}\right)
\end{bmatrix}
```
In Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total
number of qubits of `chain`, then it will return a function that requires an input of an integer.
So the following two statements are equivalent
```julia
control([i, ], j=>shift(-2π/(1<<k)))(nbit) == control(nbit, [i, ], j=>shift(-2π/(1<<k)))
```
Both of then will return a `ControlBlock` instance. If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.

Once you have construct a block, you can inspect its matrix using `mat` function.
Let's construct the circuit in dashed box A, and see the matrix of ``R_4`` gate
```julia
julia> a = A(4, 1, 4)(5)
Total: 5, DataType: Complex{Float64}
control(4)
└─ 1=>Phase Shift Gate:-0.39269908169872414


julia> mat(a.block)
2×2 Diagonal{Complex{Float64}}:
 1.0+0.0im          ⋅         
     ⋅      0.92388-0.382683im
```

Similarly, you can use `put` and `chain` to construct `PutBlock` (basic placement of a single gate) and `ChainBlock` (sequential application of `MatrixBlock`s) instances. `Yao.jl` view every component in a circuit as an `AbstractBlock`, these blocks can be integrated to perform higher level functionality.

You can check the result using classical `fft`
```@example TestQFT
# if you're using lastest julia, you need to add the fft package.
@static if VERSION >= v"0.7-"
    using FFTW
end
using Compat.Test

@test chain(num_bit, qft, iqft) |> mat ≈ eye(2^num_bit)

# define a register and get its vector representation
reg = rand_state(num_bit)
rv = reg |> statevec |> copy

# test fft
reg_qft = apply!(copy(reg) |>invorder!, qft)
kv = fft(rv)/sqrt(length(rv))
@test reg_qft |> statevec ≈ kv

# test ifft
reg_iqft = apply!(copy(reg), iqft)
kv = ifft(rv)*sqrt(length(rv))
@test reg_iqft |> statevec ≈ kv |> invorder
```

QFT and IQFT are different from FFT and IFFT in two ways,

1. they are different by a factor of ``\sqrt{2^n}`` with ``n`` the number of qubits.
2. the little end and big end will exchange after applying QFT or IQFT.


## Phase Estimation

```@example PhaseEstimation
using Compat
using Compat.Test
using Yao
using Yao.Zoo
using Yao.Blocks
using Yao.Intrinsics

"""
    phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N, T}, nshot::Int=1) -> (phase, DefaultRegister)

where,
    reg1: the output space to store phase ϕ.
    reg2: the input space with eigenvector of oracle matrix U.
    U: the oracle gate in the form of a GeneralMatrixGate.
    nshot: the number of measurements.

reference: https://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm
"""
function phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N}, nshot::Int=1) where {N}
    M = nqubits(reg1)
    iqft = QFTBlock{M}() |> adjoint
    HGates = rollrepeat(M, H)

    control_circuit = chain(M+N)
    for i = 1:M
        push!(control_circuit, control(M+N, (i,), (M+1:M+N...,)=>U))
        if i != M
            U = matrixgate(mat(U) * mat(U))
        end
    end

    # calculation
    reg1 |> HGates
    reg = join(reg1, reg2)
    apply!(reg, sequence(control_circuit, focus(1:M...), iqft)
    res = measure(reg, nshot)
    breflect.(M, res)./(1<<M), reg
end

"""
random unitary matrix.
"""
rand_unitary(N::Int) = qr(randn(N, N))[1]

######### Test Phase Estimation ##########
M = 16
N = 3

# prepair oracle matrix A
U = rand_unitary(1<<N)
phases = rand(1<<N)
ϕ = Int(0b111101)/(1<<6)
phases[3] = ϕ
signs = exp.(2pi*im.*phases)
A = U*Diagonal(signs)*U'  # notice it is unitary

# the state with phase ϕ
psi = U[:,3]

res, reg = phase_estimation(zero_state(M), register(psi), GeneralMatrixGate(A))
println("Phase is 2π * $(res[]), the exact value is 2π * $ϕ")
```
