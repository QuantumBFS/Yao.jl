function bit_flip_channel(n::Int, p::Real, locs::NTuple{N, Int}) where N
    opX = repeat(n, X, locs)
    return UnitaryChannel([igate(n), opX], [p, 1-p])
end

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

function depolarizing_channel(n::Int, p::Real)
    return DepolarizingChannel(n, p)
end
