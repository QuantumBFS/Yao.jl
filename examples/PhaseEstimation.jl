include("QFT.jl")
using Yao.Blocks
using Yao.Intrinsics
using LinearAlgebra: qr, Diagonal

"""
    phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N, T}; nshot::Int=1) -> (phase, DefaultRegister)

where,
    reg1: the output space to store phase ϕ.
    reg2: the input space with eigenvector of oracle matrix U.
    U: the oracle gate in the form of a GeneralMatrixGate.
    nshot: the number of measurements.

reference: https://en.wikipedia.org/wiki/Quantum_phase_estimation_algorithm
"""
function phase_estimation(reg1::DefaultRegister, reg2::DefaultRegister, U::GeneralMatrixGate{N}; nshot::Int=1) where {N}
    M = nqubits(reg1)
    iqft = QFT(M)'
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
    reg = join(reg2, reg1)
    reg |> control_circuit |> focus(1:M...) |> iqft
    res = measure(reg, nshot=nshot)
    breflect.(M, res)./(1<<M), reg
end

"""
random unitary matrix.
"""
rand_unitary(N::Int) = qr(randn(N, N)).Q

######### Test Phase Estimation ##########
M = 16
N = 3

# prepair oracle matrix A
U = rand_unitary(1<<N)
phases = rand(1<<N)
ϕ = Int(0b111101)/(1<<6)
phases[3] = ϕ
signs = exp.(2pi*im.*phases)
MAT = U*Diagonal(signs)*U'  # notice it is unitary

# the state with phase ϕ
psi = U[:,3]

res, reg = phase_estimation(zero_state(M), register(psi), GeneralMatrixGate(MAT))
println("Phase is 2π * $(res[]), the exact value is 2π * $ϕ")
