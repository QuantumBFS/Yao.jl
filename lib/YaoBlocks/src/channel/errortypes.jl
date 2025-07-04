abstract type AbstractErrorType end

"""
    CoherentError{BT<:AbstractBlock} <: AbstractErrorType
    CoherentError(block::BT)

Coherent unitary error channel with error gate `block`.

# Fields
- `block::BT`: the error gate
"""
struct CoherentError{BT<:AbstractBlock} <: AbstractErrorType
    block::BT
    function CoherentError(block::BT) where BT<:AbstractBlock
        isunitary(block) || throw(ArgumentError("block must be unitary, got $(block)"))
        new{BT}(block)
    end
end
quantum_channel(err::CoherentError) = MixedUnitaryChannel(err)
MixedUnitaryChannel(err::CoherentError) = MixedUnitaryChannel([err.block], [1.0])

"""
    BitFlipError(p)

Bit flip error channel with error probability `p`.
It is equivalent to the [`PauliError`](@ref) channel with `px = py = 0` and `pz = p`.

# Fields
- `p::RT`: the error probability, must be non-negative and less than or equal to 1
"""
struct BitFlipError{RT<:Real} <: AbstractErrorType
    p::RT
    function BitFlipError(p::RT) where RT<:Real
        0 ≤ p ≤ 1 || throw(ArgumentError("p must be in [0, 1], got $p"))
        new{RT}(p)
    end
end
MixedUnitaryChannel(p::BitFlipError) = MixedUnitaryChannel([I2, X], [1-p.p, p.p])

"""
    PhaseFlipError(p)

Phase flip error channel with error probability `p`.
It is equivalent to the [`PauliError`](@ref) channel with `px = py = p` and `pz = 0`.

# Fields
- `p::RT`: the error probability, must be non-negative and less than or equal to 1
"""
struct PhaseFlipError{RT<:Real} <: AbstractErrorType
    p::RT
    function PhaseFlipError(p::RT) where RT<:Real
        0 ≤ p ≤ 1 || throw(ArgumentError("p must be in [0, 1], got $p"))
        new{RT}(p)
    end
end
MixedUnitaryChannel(p::PhaseFlipError) = MixedUnitaryChannel([I2, Z], [1-p.p, p.p])

"""
    DepolarizingError(p)

Depolarizing error channel with error probability `p` for `n` qubits. It is defined as:
```math
E(ρ) = (1 - p) ρ + p \\tr(ρ) \\frac{I}{2^n}
```
where `P_i` is the projector onto the `i`-th computational basis state.

For single-qubit depolarizing error, it is equivalent to the [`PauliError`](@ref) channel with `px = py = pz = p/4`.

# Fields
- `n::Int`: the number of qubits
- `p::RT`: the error probability, must be non-negative and less than or equal to ``4^n/(4^n-1)``    
"""
struct DepolarizingError{RT<:Real} <: AbstractErrorType
    n::Int
    p::RT
    function DepolarizingError(n::Int, p::RT) where RT<:Real
        n ≥ 1 || throw(ArgumentError("n must be at least 1, got $n"))
        0 ≤ p ≤ 4^n/(4^n-1) || throw(ArgumentError("p must be in [0, 4^n/(4^n-1)] (n = $n), got $p"))
        new{RT}(n, p)
    end
end
MixedUnitaryChannel(p::DepolarizingError) = MixedUnitaryChannel(PauliError(p))
quantum_channel(p::DepolarizingError) = DepolarizingChannel(p.n, p.p)

"""
    PauliError(px, py, pz)

Pauli error channel with error probabilities `px`, `py`, and `pz`.
When applied to a density matrix `ρ`, the error channel is given by:
```math
(1 - (p_x + p_y + p_z))⋅ρ + p_x⋅X⋅ρ⋅X + p_y⋅Y⋅ρ⋅Y  + p_z⋅Z⋅ρ⋅Z
```

# Fields
- `px::RT`: the error probability of Pauli X, must be non-negative
- `py::RT`: the error probability of Pauli Y, must be non-negative
- `pz::RT`: the error probability of Pauli Z, must be non-negative
"""
struct PauliError{RT<:Real} <: AbstractErrorType
    px::RT
    py::RT
    pz::RT
    function PauliError(px::RT, py::RT, pz::RT) where RT<:Real
        px ≥ 0 || throw(ArgumentError("px must be non-negative, got $px"))
        py ≥ 0 || throw(ArgumentError("py must be non-negative, got $py"))
        pz ≥ 0 || throw(ArgumentError("pz must be non-negative, got $pz"))
        px + py + pz ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1, got $px + $py + $pz"))
        new{RT}(px, py, pz)
    end
end
# convert error types to pauli error
PauliError(err::BitFlipError{T}) where T = PauliError(err.p, zero(T), zero(T))
PauliError(err::PhaseFlipError{T}) where T = PauliError(zero(T), zero(T), err.p)
function PauliError(err::DepolarizingError{T}) where T
    @assert err.n == 1 "only single-qubit depolarizing error is supported to convert to Pauli error"
    p = err.p/4
    return PauliError(p, p, p)
end

MixedUnitaryChannel(p::PauliError) = MixedUnitaryChannel([I2, X, Y, Z], [1-p.px-p.py-p.pz, p.px, p.py, p.pz])

for T in [:BitFlipError, :PhaseFlipError, :DepolarizingError, :PauliError]
    @eval KrausChannel(err::$T) = KrausChannel(MixedUnitaryChannel(err))
end
for T in [:BitFlipError, :PhaseFlipError, :PauliError]
    @eval quantum_channel(p::$T) = MixedUnitaryChannel(p)
end

"""
    ResetError(p0, p1)

Reset error channel with error probabilities `p0` and `p1` for resetting to 0 and 1 respectively.
When applied to a density matrix `ρ`, the error channel is given by:
```math
(1 - p_0 - p_1)⋅ρ + p_0⋅(P_0⋅ρ⋅P_0 + P_d⋅ρ⋅P_d') + p_1⋅(P_1⋅ρ⋅P_1 + P_u⋅ρ⋅P_u')
```
where `P_0` and `P_1` are the projectors onto the 0 and 1 eigenstates of the Pauli Z operator, and `P_u` and `P_d` are the projectors onto the up and down eigenstates of the Pauli X operator.

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
struct ResetError{RT<:Real} <: AbstractErrorType
    p0::RT
    p1::RT
    function ResetError(p0::RT, p1::RT2) where {RT<:Real, RT2<:Real}
        T = promote_type(RT, RT2)
        p0 ≥ 0 || throw(ArgumentError("p0 must be non-negative, got $p0"))
        p1 ≥ 0 || throw(ArgumentError("p1 must be non-negative, got $p1"))
        p0 + p1 ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1, got $p0 + $p1"))
        new{T}(T(p0), T(p1))
    end
end
quantum_channel(p::ResetError) = KrausChannel(p)

# https://docs.pennylane.ai/en/stable/code/api/pennylane.ResetError.html
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

"""
    ThermalRelaxationError{RT<:Real} <: AbstractErrorType
    ThermalRelaxationError(T1, T2, time, excited_state_population=zero(RT))

Thermal relaxation error channel with error probabilities `T1`, `T2`, `time`, and `excited_state_population`.
It can be viewed as a special case of [`PhaseAmplitudeDampingError`](@ref) with:
```math
\\begin{align}
a = 1 - \\exp\\left(-\\frac{t}{T_1}\\right)\\\\
b = 1 - \\exp\\left(-\\frac{t}{T_{\\phi}}\\right)\\\\
\\end{align}
```
where ``T_{\\phi} = \\frac{T_1 T_2}{2 T_1 - T_2}``.

# Fields
- `T1::RT`: the T1 time (energy relaxation time), must be positive
- `T2::RT`: the T2 time (dephasing time), must be positive and satisfy `T2 ≤ 2T1`.
  - If `T2 ≤ T1` the error can be expressed as a mixed reset and unitary error channel.
  - If `T1 < T2 ≤ 2T1` the error must be expressed as a general non-unitary Kraus error channel.
- `time::RT`: the duration of the error, must be non-negative
- `excited_state_population::RT`: the probability of state |1⟩ at thermal equilibrium
"""
struct ThermalRelaxationError{RT<:Real} <: AbstractErrorType
    T1::RT
    T2::RT
    time::RT
    excited_state_population::RT
    function ThermalRelaxationError(T1::RT, T2::RT, time::RT2, excited_state_population::RT3=zero(RT)) where {RT<:Real, RT2<:Real, RT3<:Real}
        T = promote_type(RT, RT2, RT3)
        T1 > 0 || throw(ArgumentError("T1 must be positive, got $T1"))
        T2 > 0 || throw(ArgumentError("T2 must be positive, got $T2"))
        T2 ≤ 2T1 || throw(ArgumentError("T2 must be less than or equal to 2T1, got $T2"))
        time ≥ 0 || throw(ArgumentError("time must be non-negative, got $time"))
        0 ≤ excited_state_population ≤ 1 || throw(ArgumentError("excited_state_population must be in [0, 1], got $excited_state_population"))
        new{T}(T(T1), T(T2), T(time), T(excited_state_population))
    end
end
quantum_channel(err::ThermalRelaxationError) = KrausChannel(err)

# Ref: https://quantumcomputing.stackexchange.com/questions/27017/what-is-the-concrete-difference-between-qiskit-thermal-relaxation-error-and-phas
function KrausChannel(err::ThermalRelaxationError)
    T1, T2, time = err.T1, err.T2, err.time
    Tϕ = (T1*T2)/(2 * T1 - T2)
    amplitude = 1 - exp(-time/T1)
    phase = 1 - exp(-time/Tϕ)
    KrausChannel(PhaseAmplitudeDampingError(amplitude, phase, err.excited_state_population))
end

"""
    PhaseAmplitudeDampingError{RT<:Real} <: AbstractErrorType
    PhaseAmplitudeDampingError(amplitude::RT, phase::RT, excited_state_population::RT2=zero(RT)) where {RT<:Real, RT2<:Real}

Phase amplitude and phase damping error channel, described by the following Kraus matrices:

```math
A_0 = √(1 - p_1) * \\begin{bmatrix} 1 & 0 \\\\ 0 & √(1 - a - b) \\end{bmatrix}
A_1 = √(1 - p_1) * \\begin{bmatrix} 0 & √a \\\\ 0 & 0 \\end{bmatrix}
A_2 = √(1 - p_1) * \\begin{bmatrix} 0 & 0 \\\\ 0 & √b \\end{bmatrix}
B_0 = √p_1 * \\begin{bmatrix} √(1 - a - b) & 0 \\\\ 0 & 1 \\end{bmatrix}
B_1 = √p_1 * \\begin{bmatrix} 0 & 0 \\\\ √a & 0 \\end{bmatrix}
B_2 = √p_1 * \\begin{bmatrix} √b & 0 \\\\ 0 & 0 \\end{bmatrix}
```

where ``a`` = `amplitude`, ``b`` = `phase` and ``p_1`` = `excited_state_population`. The equilibrium state is given by:
```math
ρ_0 = \\begin{bmatrix} 1-p_1 & 0 \\\\ 0 & p_1 \\end{bmatrix}
```

# Fields
- `amplitude::RT`: the amplitude damping error parameter, must be non-negative
- `phase::RT`: the phase damping error parameter, must be non-negative and satisfy `phase + amplitude ≤ 1`
- `excited_state_population::RT`: the probability of state |1⟩ at thermal equilibrium, must be in [0, 1]
"""
struct PhaseAmplitudeDampingError{RT<:Real} <: AbstractErrorType
    amplitude::RT
    phase::RT
    excited_state_population::RT
    function PhaseAmplitudeDampingError(amplitude::RT, phase::RT, excited_state_population::RT2=zero(RT)) where {RT<:Real, RT2<:Real}
        T = promote_type(RT, RT2)
        0 ≤ amplitude ≤ 1 || throw(ArgumentError("amplitude must be in [0, 1], got $amplitude"))
        0 ≤ phase ≤ 1 || throw(ArgumentError("phase must be in [0, 1], got $phase"))
        phase + amplitude ≤ 1 || throw(ArgumentError("phase + amplitude must be less than or equal to 1, got $phase + $amplitude"))
        0 ≤ excited_state_population ≤ 1 || throw(ArgumentError("excited_state_population must be in [0, 1], got $excited_state_population"))
        new{T}(T(amplitude), T(phase), T(excited_state_population))
    end
end

quantum_channel(err::PhaseAmplitudeDampingError) = KrausChannel(err)
function KrausChannel(err::PhaseAmplitudeDampingError{T}) where T
    CT = Complex{T}
    a, b, p1 = err.amplitude, err.phase, err.excited_state_population
    blocks = AbstractBlock{2}[]
    if !(p1 ≈ 1)
        # dampling operators to 0 state
        push!(blocks, matblock(sqrt(1 - p1) * CT[1 0; 0 sqrt(1 - a - b)]; tag = "A0"))
        if !iszero(a)
            push!(blocks, matblock(sqrt(1 - p1) * CT[0 sqrt(a); 0 0]; tag = "A1"))
        end
        if !iszero(b)
            push!(blocks, matblock(sqrt(1 - p1) * CT[0 0; 0 sqrt(b)]; tag = "A2"))
        end
    end
    if !(p1 ≈ 0)
        # dampling operators to 1 state
        push!(blocks, matblock(sqrt(p1) * CT[sqrt(1 - a - b) 0; 0 1]; tag = "B0"))
        if !iszero(a)
            push!(blocks, matblock(sqrt(p1) * CT[0 0; sqrt(a) 0]; tag = "B1"))
        end
        if !iszero(b)
            push!(blocks, matblock(sqrt(p1) * CT[sqrt(b) 0; 0 0]; tag = "B2"))
        end
    end
    return KrausChannel(blocks)
end

"""
    PhaseDampingError{RT<:Real} <: AbstractErrorType
    PhaseDampingError(phase::RT) where RT<:Real

Phase damping error channel, described by the following Kraus matrices:

```math
A_0 = \\begin{bmatrix} 1 & 0 \\\\ 0 & √(1 - b) \\end{bmatrix}
A_2 = \\begin{bmatrix} 0 & 0 \\\\ 0 & √b \\end{bmatrix}
```

where ``b`` = `phase`.
The equilibrium state is given by:
```math
ρ_0 = \\begin{bmatrix} ρ_{00} & 0 \\\\ 0 & ρ_{11} \\end{bmatrix}
```
where ``ρ_{00}`` and ``ρ_{11}`` are the diagonal elements of the input density matrix.

# Fields
- `phase::RT`: the phase damping error parameter, must be non-negative
"""
struct PhaseDampingError{RT<:Real} <: AbstractErrorType
    phase::RT
    function PhaseDampingError(phase::RT) where RT<:Real
        0 ≤ phase ≤ 1 || throw(ArgumentError("phase must be in [0, 1], got $phase"))
        new{RT}(phase)
    end
end
quantum_channel(err::PhaseDampingError) = KrausChannel(err)
KrausChannel(err::PhaseDampingError{T}) where T = KrausChannel(PhaseAmplitudeDampingError(zero(T), err.phase, zero(T)))

"""
    AmplitudeDampingError{RT<:Real} <: AbstractErrorType
    AmplitudeDampingError(amplitude::RT, excited_state_population::RT2=zero(RT)) where {RT<:Real, RT2<:Real}

Amplitude damping error channel, described by the following Kraus matrices:

```math
A_0 = √(1 - p_1) * \\begin{bmatrix} 1 & 0 \\\\ 0 & √(1 - a) \\end{bmatrix}
A_1 = √(1 - p_1) * \\begin{bmatrix} 0 & √a \\\\ 0 & 0 \\end{bmatrix}
B_0 = √p_1 * \\begin{bmatrix} √(1 - a) & 0 \\\\ 0 & 1 \\end{bmatrix}
B_1 = √p_1 * \\begin{bmatrix} 0 & 0 \\\\ √a & 0 \\end{bmatrix}
```

where ``a`` = `amplitude` and ``p_1`` = `excited_state_population`. The equilibrium state is given by:
```math
ρ_0 = \\begin{bmatrix} 1-p_1 & 0 \\\\ 0 & p_1 \\end{bmatrix}
```

# Fields
- `amplitude::RT`: the amplitude damping error parameter, must be non-negative
- `excited_state_population::RT`: the probability of state |1⟩ at thermal equilibrium, must be non-negative and less than or equal to 1
"""
struct AmplitudeDampingError{RT<:Real} <: AbstractErrorType
    amplitude::RT
    excited_state_population::RT
    function AmplitudeDampingError(amplitude::RT, excited_state_population::RT2=zero(RT)) where {RT<:Real, RT2<:Real}
        T = promote_type(RT, RT2)
        0 ≤ amplitude ≤ 1 || throw(ArgumentError("amplitude must be in [0, 1], got $amplitude"))
        0 ≤ excited_state_population ≤ 1 || throw(ArgumentError("excited_state_population must be in [0, 1], got $excited_state_population"))
        new{T}(T(amplitude), T(excited_state_population))
    end
end
quantum_channel(err::AmplitudeDampingError) = KrausChannel(err)
KrausChannel(err::AmplitudeDampingError{T}) where T = KrausChannel(PhaseAmplitudeDampingError(err.amplitude, zero(T), err.excited_state_population))

# convert error types to superop
SuperOp(::Type{T}, x::AbstractErrorType) where T = SuperOp(T, quantum_channel(x))
SuperOp(x::AbstractErrorType) = SuperOp(Complex{Float64}, x)