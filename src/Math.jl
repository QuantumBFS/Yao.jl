"""
    rand_unitary(N::Int) -> Matrix

Random unitary matrix.
"""
function rand_unitary(N::Int)
    qr(randn(ComplexF64, N, N)).Q |> Matrix
end

"""
    rand_hermitian(N::Int) -> Matrix

Random hermitian matrix.
"""
function rand_hermitian(N::Int)
    A = randn(ComplexF64, N, N)
    A + A'
end

"""
Function to make a unify matrixgate.

TODO:
deprecated this function.
"""
function matrix_unify(A)
    U = exp(2π*im.*A)
    UG = matrixgate(U)
    UG
end

############ Leo's Magic Tricks ################
Base.:(|>)(reg::AbstractRegister, circuit::AbstractBlock) = apply!(reg, circuit)
⊗(reg::AbstractRegister, reg2::AbstractRegister) = join(reg, reg2)
