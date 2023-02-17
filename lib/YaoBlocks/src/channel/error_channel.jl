"""
    bit_flip_channel(p::Real)

Create a bit flip channel as a [`UnitaryChannel`](@ref).

```math
p⋅ρ + (1-p)⋅XρX
```
"""
function bit_flip_channel(p::Real)
    return unitary_channel([I2, X], [p, 1-p])
end

function pauli_error_channel(; px::Real, py::Real=px, pz::Real=px)
    pz + px + py ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1"))
    return UnitaryChannel(
        [I2, X, Y, Z],
        [1-(px+py+pz), px, py, pz],
    )
end

"""
    phase_flip_channel(::Real)

Create a phase flip channel as [`UnitaryChannel`](@ref).

```math
p⋅ρ + (1-p)⋅ZρZ
```
"""
function phase_flip_channel(p::Real)
    return UnitaryChannel([I2, Z], [p, 1-p])
end

struct DepolarizingChannel{T} <: PrimitiveBlock{2}
    n::Int # n is not necessary but this is required by a block
    p::T
end

YaoAPI.nqudits(ch::DepolarizingChannel) = ch.n

function YaoAPI.unsafe_apply!(dm::DensityMatrix, ch::DepolarizingChannel)
    regscale!(dm, 1 - ch.p)
    dm.state .+= ch.p/(2^nqubits(dm)) * IMatrix(size(dm.state, 1))
    return dm
end

"""
    depolarizing_channel(n::Int; p::Real)

Create a global depolarizing channel.

### Arguments
- `n`: number of qubits.

### Keyword Arguments
- `p`: probability of this error to occur.

### See also
[`single_qubit_depolarizing_channel`](@ref) and [`two_qubit_depolarizing_channel`](@ref)
for depolarizing channels acting on only one or two qubits.
"""
function depolarizing_channel(n::Int; p::Real)
    return DepolarizingChannel(n, p)
end

"""
    single_qubit_depolarizing_channel(p::Real)

Create a single-qubit depolarizing channel.

The factor of 3/4 in front of p ensures that 
`single_qubit_depolarizing_channel(p) == depolarizing_channel(1, p)`

```math
(1 - 3p/4 ⋅ρ) + p/4⋅(XρX + YρY + ZρZ)
```
"""
function single_qubit_depolarizing_channel(p::Real)
    return pauli_error_channel(px=p/4, py=p/4, pz=p/4)
end

"""
    two_qubit_depolarizing_channel(p::Real)

Create a two-qubit depolarizing channel. Note that this is not the same 
as `kron(single_qubit_depolarizing_channel(p), single_qubit_depolarizing_channel(p))`.
"""
function two_qubit_depolarizing_channel(p::Real)
    return UnitaryChannel(
        [kron(I2, I2), kron(I2, X), kron(I2, Y), kron(I2, Z),
         kron(X, I2), kron(X, X), kron(X, Y), kron(X, Z),
         kron(Y, I2), kron(Y, X), kron(Y, Y), kron(Y, Z),
         kron(Z, I2), kron(Z, X), kron(Z, Y), kron(Z, Z),
        ],
        [1-15p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
        ],
    )
end
