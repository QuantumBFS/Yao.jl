# Quantum Fourier Transform
![ghz](../assets/figures/qft.png)

```@example QFT
using Yao

# Control-R(k) gate in block-A
A(i::Int, j::Int, k::Int) = control([i, ], j=>shift(2π/(1<<k)))
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

Now let's check the result using classical `fft`
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
reg_qft = copy(reg) |>invorder! |> qft
kv = ifft(rv)*sqrt(length(rv))
@test reg_qft |> statevec ≈ kv

# test ifft
reg_iqft = copy(reg) |>iqft
kv = fft(rv)/sqrt(length(rv))
@test reg_iqft |> statevec ≈ kv |> invorder
```

QFT and IQFT are different from FFT and IFFT in three ways,

1. they are different by a factor of ``\sqrt{2^n}`` with ``n`` the number of qubits.
2. the little end and big end will exchange after applying QFT or IQFT.
3. dur to the convention, QFT is more related to IFFT rather than FFT.

In Yao, factory methods for blocks will be loaded lazily. For example, if you missed the total
number of qubits of `chain`, then it will return a function that requires an input of an integer.

If you missed the total number of qubits. It is OK. Just go on, it will be filled when its possible.

```julia
chain(4, repeat(1=>X), kron(2=>Y))
```
