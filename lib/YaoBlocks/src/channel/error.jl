"""
    bit_flip_channel(n::Int, p::Real, locs::NTuple{N, Int}) where N

Create a bit flip channel as [`UnitaryChannel`](@ref).

```math
p⋅ρ + (1-p)⋅XρX
```

### Arguments

- `n`: number of qubits.
- `p`: probability of bit flips.
- `locs`: locations of qubits that has this error to occur.
"""
function bit_flip_channel(n::Int, p::Real, locs::NTuple{N, Int}) where N
    opX = repeat(n, X, locs)
    return UnitaryChannel([igate(n), opX], [p, 1-p])
end

"""
    phase_flip_channel(n::Int, p::Real, locs::NTuple{N, Int}) where N

Create a phase flip channel as [`UnitaryChannel`](@ref).

```math
p⋅ρ + (1-p)⋅ZρZ
```

### Arguments
- `n`: number of qubits.
- `p`: probability of this error to occur.
- `locs`: locations of qubits that has this error to occur.
"""
function phase_flip_channel(n::Int, p::Real, locs::NTuple{N, Int}) where N
    opZ = repeat(n, Z, locs)
    return UnitaryChannel([igate(n), opZ], [p, 1-p])    
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
    depolarizing_channel(n::Int, p::Real)

Create a depolarizing channel.

# Arguments

### Arguments
- `n`: number of qubits.
- `p`: probability of this error to occur.
"""
function depolarizing_channel(n::Int, p::Real)
    return DepolarizingChannel(n, p)
end
