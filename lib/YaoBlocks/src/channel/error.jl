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
    dm.state .+= ch.p/2 * IMatrix(size(dm.state, 1))
    return dm
end

"""
    depolarizing_channel(n::Int; p::Real)

Create a depolarizing channel.

# Arguments

### Arguments
- `n`: number of qubits.

### Keyword Arguments
- `p`: probability of this error to occur.
"""
function depolarizing_channel(n::Int; p::Real)
    return DepolarizingChannel(n, p)
end
