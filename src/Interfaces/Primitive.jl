export phase, shift, Rx, Ry, Rz, rot

include("PauliGates.jl")

"""
    H

The Hadamard gate acts on a single qubit. It maps the basis state ``|0\\rangle``
to ``\\frac{|0\\rangle + |1\\rangle}{\\sqrt{2}}`` and ``|1\\rangle`` to
``\\frac{|0\\rangle - |1\\rangle}{\\sqrt{2}}``, which means that a measurement
will have equal probabilities to become 1 or 0. It is representated by the Hadamard matrix:

```math
H = \\frac{1}{\\sqrt{2}} \\begin{pmatrix}
1 & 1 \\\\
1 & -1
\\end{pmatrix}
```
"""
H

"""
    phase([type=Yao.DefaultType], [theta=0.0]) -> PhaseGate{:global}

Returns a global phase gate.
"""
function phase end

phase(::Type{T}, theta) where {T <: Complex} = PhaseGate{:global, real(T)}(theta)
phase(theta=0.0) = phase(DefaultType, theta)

"""
    shift([type=Yao.DefaultType], [theta=0.0]) -> PhaseGate{:shift}

Returns a phase shift gate.
"""
function shift end

shift(::Type{T}, theta) where {T <: Complex} = PhaseGate{:shift, real(T)}(theta)
shift(theta=0.0) = shift(DefaultType, theta)

"""
    Rx([type=Yao.DefaultType], [theta=0.0]) -> RotationGate{type, X}

Returns a rotation X gate.
"""
function Rx end

"""
    Ry([type=Yao.DefaultType], [theta=0.0]) -> RotationGate{type, Y}

Returns a rotation Y gate.
"""
function Ry end

"""
    Rz([type=Yao.DefaultType], [theta=0.0]) -> RotationGate{type, Z}

Returns a rotation Z gate.
"""
function Rz end

for (FNAME, NAME) in [
    (:Rx, :X),
    (:Ry, :Y),
    (:Rz, :Z),
]

    GT = Symbol(join([NAME, "Gate"]))
    @eval begin
        $FNAME(::Type{T}, theta=0.0) where {T <: Complex} = RotationGate{real(T), $GT{T}}($NAME(T), theta)
        $FNAME(theta=0.0) = $FNAME(DefaultType, theta)
    end

end

"""
    rot([type=Yao.DefaultType], U, [theta=0.0]) -> RotationGate{type, U}

Returns an arbitrary rotation gate on U.
"""
function rot end

rot(::Type{T}, U::GT, theta=0.0) where {T, GT} = RotationGate{real(T), GT}(U, theta)
rot(U::MatrixBlock, theta=0.0) = rot(DefaultType, U, theta)
