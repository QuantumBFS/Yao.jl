export H, phase, shift, Rx, Ry, Rz, rot, swap, I2, reflect, matrixgate, PauliGate, S, T, Sdag, Tdag


export X, Y, Z

DESCRIPTIONS = [
"""It is the quantum equivalent of the NOT gate for classical computers
(with respect to the standard basis ``|0\\rangle``, ``|1\\rangle``).""",

"""It equates to a rotation around the Y-axis of the Bloch sphere by ``\\pi`` radians.
It maps ``|0\\rangle`` to ``i|1\\rangle`` and ``|1\\rangle`` to ``-i|0\\rangle``.""",

"""It equates to a rotation around the Z-axis of the Bloch sphere by ``\\pi`` radians.
Thus, it is a special case of a phase shift gate (see `shift`) with ``\\theta = \\pi``.
It leaves the basis state ``|0\\rangle`` unchanged and maps ``|1\\rangle`` to ``-|1\\rangle``.
Due to this nature, it is sometimes called phase-flip."""
]

MATDOCS = [
"""X = \\begin{pmatrix}
0 & 1\\\\
1 & 0
\\end{pmatrix}""",

"""Y = \\begin{pmatrix}
0 & -i\\\\
i & 0
\\end{pmatrix}""",

"""Z = \\begin{pmatrix}
1 & 0\\\\
0 & -1
\\end{pmatrix}"""
]

# generate docstring for Pauli gates
for (name, d, m) in zip([:X, :Y, :Z], DESCRIPTIONS, MATDOCS)

docstr = """
    $name

The Pauli-$name gate acts on a single qubit. $d It is represented by the Pauli $name matrix:

```math
$m
```
"""

tstr =
"""
    $(name)Gate{T} <: ConstantGate{1, T}

The block type for Pauli-$name gate. See docs for `$name`
for more information.
"""


@eval begin
@doc $docstr $name
@doc $tstr $(Symbol(name, "Gate"))
end

end


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
    phase([type=Yao.DefaultType], theta) -> PhaseGate{:global}

Returns a global phase gate.
"""
function phase end

phase(::Type{T}, theta) where {T <: Complex} = PhaseGate{real(T)}(real(T)(theta))
phase(theta) = phase(DefaultType, theta)

"""
    shift([type=Yao.DefaultType], theta) -> PhaseGate{:shift}

Returns a phase shift gate.
"""
function shift end

shift(::Type{T}, theta) where {T <: Complex} = ShiftGate{real(T)}(real(T)(theta))
shift(theta) = shift(DefaultType, theta)

"""
    Rx([type=Yao.DefaultType], theta) -> RotationGate{1, type, X}

Returns a rotation X gate.
"""
function Rx end

"""
    Ry([type=Yao.DefaultType], theta) -> RotationGate{1, type, Y}

Returns a rotation Y gate.
"""
function Ry end

"""
    Rz([type=Yao.DefaultType], theta) -> RotationGate{1, type, Z}

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
        $FNAME(::Type{T}, theta) where {T <: Complex} = RotationGate{1, real(T), $GT{T}}($GT{T}(), theta)
        $FNAME(theta) = $FNAME(DefaultType, theta)
    end

end

"""
    rot([type=Yao.DefaultType], U, theta) -> RotationGate{N, type, U}

Returns an arbitrary rotation gate on U.
"""
function rot end

rot(U::GT, theta) where {N, T, GT<:MatrixBlock{N, Complex{T}}} = RotationGate{N, T, GT}(U, T(theta))

"""
    swap([n], [type], line1, line2) -> Swap

Returns a swap gate on `line1` and `line2`
"""
function swap end

swap(n::Int, ::Type{T}, line1::Int, line2::Int) where T = Swap{n, T}(line1, line2)
swap(::Type{T}, line1::Int, line2::Int) where T = n -> swap(n, T, line1, line2)
swap(n::Int, line1::Int, line2::Int) = Swap{n, DefaultType}(line1, line2)
swap(line1::Int, line2::Int) = n->swap(n, line1, line2)

"""
    reflect(mirror::DenseRegister{1}) -> ReflectBlock
    reflect(mirror::Vector) -> ReflectBlock

Return an ReflectBlock along with state vector mirror as the axis.
"""
function reflect end

reflect(mirror::Vector) = ReflectBlock(mirror)
reflect(mirror::DenseRegister{1}) = reflect(mirror|>statevec)

"""
    matrixgate(matrix::AbstractMatrix) -> GeneralMatrixGate
    matrixgate(matrix::MatrixBlock) -> GeneralMatrixGate

Construct a general matrix gate.
"""
matrixgate(matrix::AbstractMatrix) = GeneralMatrixGate(matrix)
matrixgate(matrix::MatrixBlock) = GeneralMatrixGate(mat(matrix))
