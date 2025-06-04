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
"""
function depolarizing_channel(n::Int; p::Real)
    return DepolarizingChannel(n, p)
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