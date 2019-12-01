using Test, YaoBase, BitBasis, YaoArrayRegister, YaoBlocks, LinearAlgebra

A(i, j) = control(i, j => shift(2π / (1 << (i - j + 1))))
B(n, i) = chain(n, i == j ? put(i => H) : A(j, i) for j = i:n)
qft(n) = chain(B(n, i) for i = 1:n)

struct QFT{N,T} <: PrimitiveBlock{N,T} end

QFT(::Type{T}, n::Int) where {T} = QFT{n,T}()
QFT(n::Int) = QFT(ComplexF64, n)
circuit(::QFT{N}) where {N} = qft(N)
YaoBlocks.mat(x::QFT) = mat(circuit(x))
YaoBlocks.print_block(io::IO, x::QFT{N}) where {N} = print(io, "QFT($N)")

using FFTW, LinearAlgebra

function YaoBlocks.apply!(r::ArrayReg, x::QFT)
    α = sqrt(length(statevec(r)))
    invorder!(r)
    lmul!(α, ifft!(statevec(r)))
    return r
end

r = rand_state(5)
r1 = r |> copy |> QFT(5)
r2 = r |> copy |> circuit(QFT(5))

@test r1 ≈ r2


Hadamards(n) = repeat(H, 1:n)
ControlU(n, m, U) = chain(n + m, control(k, n+1:n+m => matblock(U^(2^(k - 1)))) for k = 1:n)
PE(n, m, U) = chain(
    n + m, # total number of the qubits
    concentrate(Hadamards(n), 1:n), # apply H in local scope
    ControlU(n, m, U),
    concentrate(QFT(n)', 1:n),
)



using LinearAlgebra

N, M = 3, 5
P = eigen(rand_unitary(1 << M)).vectors
θ = Int(0b110) / 1 << N
phases = rand(1 << M)
phases[bit"010"] = θ
U = P * Diagonal(exp.(2π * im * phases)) * P'

psi = P[:, 3]

λ = exp(2π * im * θ)
@test isapprox(U * psi, λ * psi; atol = 1e-8)

r = join(ArrayReg(psi), zero_state(N))
r |> PE(N, M, U)

p, a = findmax(probs(partial_tr(r, N+1:N+M)))
@test p ≈ 1.0
@test breflect(Int(0b110); nbits = 3) == a - 1
