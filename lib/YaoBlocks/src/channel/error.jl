"""
    bit_flip_channel(n::Int, locs::NTuple{N, Int}; p::Real) where N

Create a bit flip channel as [`UnitaryChannel`](@ref). If number of `locs`
is larger than 1, then the cumulated error channel will be applied.

```math
p⋅ρ + (1-p)⋅XρX
```

### Arguments

- `n`: number of qubits.
- `locs`: locations of qubits that has this error to occur.

### Keyword Arguments

- `p`: probability of bit flips.
"""
function bit_flip_channel(n::Int, loc::Int; p::Real)
    return UnitaryChannel([igate(n), put(n, loc=>X)], [p, 1-p])
end

function pauli_error_channel(n::Int, loc::Int; pz::Real, px::Real=pz, py::Real=pz)
    pz + px + py ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1"))
    return UnitaryChannel(
        [igate(n), put(n, loc=>X), put(n, loc=>Y), put(n, loc=>Z)],
        [1-(px+py+pz), px, py, pz],
    )
end

"""
    phase_flip_channel(n::Int, locs::NTuple{N, Int}; p::Real)

Create a phase flip channel as [`UnitaryChannel`](@ref). If number of `locs`
is larger than 1, then the cumulated error channel will be applied.

```math
p⋅ρ + (1-p)⋅ZρZ
```

### Arguments
- `n`: number of qubits.
- `locs`: locations of qubits that has this error to occur.

### Keyword Arguments
- `p`: probability of this error to occur.
"""
function phase_flip_channel(n::Int, loc::Int; p::Real)
    return UnitaryChannel([igate(n), put(n, loc=>Z)], [p, 1-p])
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

# Arguments

### Arguments
- `n`: number of qubits.

### Keyword Arguments
- `p`: probability of this error to occur.

# See also
[single_qubit_depolarizing_channel](@ref) and [two_qubit_depolarizing_channel](@ref)
for depolarizing channels acting on only one or two qubits.
"""
function depolarizing_channel(n::Int; p::Real)
    return DepolarizingChannel(n, p)
end

"""
    single_qubit_depolarizing_channel(n::Int, loc::Int; p::Real)

Create a single-qubit depolarizing channel.

The factor of 3/4 in front of p ensures that 
``single_qubit_depolarizing_channel(1, 1, p) == depolarizing_channel(1, p)``

```math
(1 - 3p/4 ⋅ρ) + p/4⋅(XρX + YρY + ZρZ)
```

# Arguments

### Arguments
- `n`: number of qubits.
- `loc`: qubit to apply the channel to

### Keyword Arguments
- `p`: probability of an error to occur.
"""
function single_qubit_depolarizing_channel(n::Int, loc::Int; p::Real)
    return pauli_error_channel(n, loc, px=p/4, py=p/4, pz=p/4)
end

"""
    two_qubit_depolarizing_channel(n::Int, locs::NTuple{2,Int}; p::Real)

Create a two-qubit depolarizing channel.

# Arguments

### Arguments
- `n`: number of qubits.
- `locs`: The two qubits to apply the channel to

### Keyword Arguments
- `p`: probability of an error to occur.
"""
function two_qubit_depolarizing_channel(n::Int, locs::NTuple{2,Int}; p::Real)
    loc1, loc2 = locs
    return UnitaryChannel(
        [igate(n), put(n, loc2=>X), put(n, loc2=>Y), put(n, loc2=>Z),
         put(n, loc1=>X), kron(n, loc1=>X, loc2=>X), kron(n, loc1=>X, loc2=>Y), kron(n, loc1=>X, loc2=>Z),
         put(n, loc1=>Y), kron(n, loc1=>Y, loc2=>X), kron(n, loc1=>Y, loc2=>Y), kron(n, loc1=>Y, loc2=>Z),
         put(n, loc1=>Z), kron(n, loc1=>Z, loc2=>X), kron(n, loc1=>Z, loc2=>Y), kron(n, loc1=>Z, loc2=>Z),
        ],
        [1-15p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
        ],
    )
end
