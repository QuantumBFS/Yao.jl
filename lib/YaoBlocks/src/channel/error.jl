function single_qubit_error_composite_probabilties(total::Int, p::Real)
    return map(0:1<<total-1) do syndrome
        prod(1:total) do i
            if readbit(syndrome, i) == 1
                (1 - p)
            else
                p
            end
        end
    end
end

function single_qubit_error_composite_operators(err, n::Int, locs::NTuple)
    total = length(locs)
    return map(0:1<<total-1) do syndrome
        syndrome == 0 && return igate(n)
        op = chain(n)
        for i in 1:total
            if readbit(syndrome, i) == 1
                push!(op, put(locs[i]=>err))
            end
        end
        op
    end
end

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
function bit_flip_channel(n::Int, locs::NTuple{N, Int}; p::Real) where N
    ps = single_qubit_error_composite_probabilties(N, p)
    op = single_qubit_error_composite_operators(X, n, locs)
    return UnitaryChannel(op, ps)
end

function pauli_error_channel(n::Int, locs::NTuple{N, Int}; pz::Real, px::Real=pz, py::Real=pz) where N
    pz + px + py ≤ 1 || throw(ArgumentError("sum of error probability is larger than 1"))

    # TODO: figure out the cumulated probability
    return chain(
        UnitaryChannel(
            [igate(n), put(n, loc=>X), put(n, loc=>Y), put(n, loc=>Z)],
            [1-(px+py+pz), px, py, pz],
        ) for loc in locs
    )
end

"""
    phase_flip_channel(n::Int, locs::NTuple{N, Int}; p::Real) where N

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
function phase_flip_channel(n::Int, locs::NTuple{N, Int}; p::Real) where N
    ps = single_qubit_error_composite_probabilties(N, p)
    op = single_qubit_error_composite_operators(Z, n, locs)
    return UnitaryChannel(op, ps)   
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
