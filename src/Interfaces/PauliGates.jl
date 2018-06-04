export X, Y, Z

DESCRIPTIONS = [
"""It is the quantum equivalent of the NOT gate for classical computers
(with respect to the standard basis ``|0\\rangle``, ``|1\\rangle``).""",

"""It equates to a rotation around the Y-axis of the Bloch sphere by ``\\pi`` radians.
It maps ``|0\\rangle`` to ``i|1\\rangle`` and ``|1\\rangle`` to ``-i|0\\rangle``.""",

"""It equates to a rotation around the Z-axis of the Bloch sphere by ``\\pi`` radians.
Thus, it is a special case of a phase shift gate (see `shift`) with ``\\theta = \\pi``.
It leaves the basis state ``|0\\rangle`` unchanged and maps ``|1\\range`` to ``-|1\\rangle``.
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
