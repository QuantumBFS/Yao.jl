abstract type AbstractErrorType end

"""
    BitFlipError(p)

Bit flip error channel with error probability `p`.
It is equivalent to the [`PauliError`](@ref) channel with `px = py = 0` and `pz = p`.
"""
struct BitFlipError{RT<:Real} <: AbstractErrorType
    p::RT
end
MixedUnitaryChannel(p::BitFlipError) = MixedUnitaryChannel([I2, X], [1-p.p, p.p])

"""
    PhaseFlipError(p)

Phase flip error channel with error probability `p`.
It is equivalent to the [`PauliError`](@ref) channel with `px = py = p` and `pz = 0`.
"""
struct PhaseFlipError{RT<:Real} <: AbstractErrorType
    p::RT
end
MixedUnitaryChannel(p::PhaseFlipError) = MixedUnitaryChannel([I2, Z], [1-p.p, p.p])

"""
    DepolarizingError(p)

Depolarizing error channel with error probability `p`.
It is equivalent to the [`PauliError`](@ref) channel with `px = py = pz = p/3`.
"""
struct DepolarizingError{RT<:Real} <: AbstractErrorType
    p::RT
end
MixedUnitaryChannel(p::DepolarizingError) = MixedUnitaryChannel(PauliError(p))

"""
    PauliError(px, py, pz)

Pauli error channel with error probabilities `px`, `py`, and `pz`.
When applied to a density matrix `ρ`, the error channel is given by:
```math
(1 - (p_x + p_y + p_z))⋅ρ + p_x⋅X⋅ρ⋅X + p_y⋅Y⋅ρ⋅Y  + p_z⋅Z⋅ρ⋅Z
```
"""
struct PauliError{RT<:Real} <: AbstractErrorType
    px::RT
    py::RT
    pz::RT
end
# convert error types to pauli error
PauliError(err::BitFlipError{T}) where T = PauliError(err.p, zero(T), zero(T))
PauliError(err::PhaseFlipError{T}) where T = PauliError(zero(T), zero(T), err.p)
PauliError(err::DepolarizingError{T}) where T = PauliError(err.p/4, err.p/4, err.p/4)

MixedUnitaryChannel(p::PauliError) = MixedUnitaryChannel([I2, X, Y, Z], [1-p.px-p.py-p.pz, p.px, p.py, p.pz])

for T in [:BitFlipError, :PhaseFlipError, :DepolarizingError, :PauliError]
    @eval KrausChannel(err::$T) = KrausChannel(MixedUnitaryChannel(err))
end

"""
    ResetError(p0, p1)

Reset error channel with error probabilities `p0` and `p1` for resetting to 0 and 1 respectively.
When applied to a density matrix `ρ`, the error channel is given by:
```math
(1 - p_0 - p_1)⋅ρ + p_0⋅(P_0⋅ρ⋅P_0 + P_d⋅ρ⋅P_d') + p_1⋅(P_1⋅ρ⋅P_1 + P_u⋅ρ⋅P_u')
```
where `P_0` and `P_1` are the projectors onto the 0 and 1 eigenstates of the Pauli Z operator, and `P_u` and `P_d` are the projectors onto the up and down eigenstates of the Pauli X operator.
"""
struct ResetError{RT<:Real} <: AbstractErrorType
    p0::RT
    p1::RT
end


# https://docs.pennylane.ai/en/stable/code/api/pennylane.ResetError.html
"""
Single-qubit Reset error channel.

This channel is modelled by the following Kraus matrices:
```math
\\begin{align}
K_0 = \\sqrt{1 - p_0 - p_1} I\\\\
K_1 = \\sqrt{p_0} P_0\\\\
K_2 = \\sqrt{p_0} P_d\\\\
K_3 = \\sqrt{p_1} P_1\\\\
K_4 = \\sqrt{p_1} P_u
\\end{align}
```
where ``p_0 \\in [0,1]`` is the probability of a reset to 0, and ``p_1 \\in [0,1]`` is the probability of a reset to 1 error.

### Note
The Kraus operators are not unique, and the above is not the simplest form.
"""
function KrausChannel(err::ResetError)
    p0, p1 = err.p0, err.p1
    p0 + p1 ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1"))
    operators = AbstractBlock{2}[sqrt(1 - p0 - p1) * I2]
    if !iszero(p0)
        push!(operators, sqrt(p0) * ConstGate.P0)
        push!(operators, sqrt(p0) * ConstGate.Pd)
    end
    if !iszero(p1)
        push!(operators, sqrt(p1) * ConstGate.P1)
        push!(operators, sqrt(p1) * ConstGate.Pu)
    end
    return KrausChannel(operators)
end

# convert error types to superop
SuperOp(::Type{T}, x::AbstractErrorType) where T = SuperOp(T, KrausChannel(x))
SuperOp(x::AbstractErrorType) = SuperOp(Complex{Float64}, x)