using Yao

A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))

R4 = A(4, 1)

R4(5)

mat(R4(5))

B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)

qft(n) = chain(B(n, k) for k in 1:n)
qft(4)

struct QFT <: PrimitiveBlock{2}
    n::Int
end

YaoBlocks.nqudits(q::QFT) = q.n

circuit(q::QFT) = qft(q.n)

YaoBlocks.mat(::Type{T}, x::QFT) where T = mat(T, circuit(x))

YaoBlocks.print_block(io::IO, x::QFT) = print(io, "QFT($(x.n))")

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
r1 ≈ r2

QFT(5)'

Hadamards(n) = repeat(H, 1:n)

ControlU(n, m, U) = chain(n+m, control(k, n+1:n+m=>matblock(U^(2^(k-1)))) for k in 1:n)

PE(n, m, U) =
    chain(n+m, # total number of the qubits
        subroutine(Hadamards(n), 1:n), # apply H in local scope
        ControlU(n, m, U),
        subroutine(QFT(n)', 1:n))

r = rand_state(5)

focus!(r, 1:3)

relax!(r, 1:3)

N, M = 3, 5
P = eigen(rand_unitary(1<<M)).vectors
θ = Int(0b110) / 1<<N
phases = rand(1<<M)
phases[0b010+1] = θ
U = P * Diagonal(exp.(2π * im * phases)) * P'

psi = P[:, 3]

r = join(ArrayReg(psi), zero_state(N))
r |> PE(N, M, U)

results = measure(r, 1:N; nshots=1)

using BitBasis
estimated_phase = bfloat(results[]; nbits=N)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

