using ExponentialUtilities, YaoArrayRegister

export TimeEvolution

"""
    TimeEvolution{N, TT, GT} <: PrimitiveBlock{N, ComplexF64}

TimeEvolution, where GT is block type. input matrix should be hermitian.
"""
struct TimeEvolution{N, T, Tt, Hamilton <: AbstractBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    H::BlockMap{Complex{T}, Hamilton}
    dt::Tt
    tol::T

    function TimeEvolution(
        H::BlockMap{Complex{T}, TH},
        dt::Tt, tol::T) where {N, Tt, T, TH <: AbstractBlock{N, Complex{T}}}
        # The time evolution Hamiltonian has to be a Hermitian
        ishermitian(H) || error("Time evolution Hamiltonian has to be a Hermitian")
        return new{N, T, Tt, TH}(H, dt, tol)
    end
end

"""
    TimeEvolution(H, dt[; tol::Real=1e-7])

Create a [`TimeEvolution`](@ref) block with Hamiltonian `H` and time step `dt`. The
`TimeEvolution` block will use Krylove based `expv` to calculate time propagation.

Optional keywords are tolerance `tol` (default is `1e-7`)
`TimeEvolution` block can also be used for
[imaginary time evolution](http://large.stanford.edu/courses/2008/ph372/behroozi2/) if dt is complex.
"""
TimeEvolution(H::AbstractBlock, dt; tol::Real=1e-7) =
    TimeEvolution(BlockMap(H), dt, tol)

TimeEvolution(M::BlockMap, dt; tol::Real) =
    TimeEvolution(M, dt, tol)

function mat(te::TimeEvolution{N}) where N
    A = Matrix(mat(te.H.block))
    return exp(te.dt * A)
end

function apply!(reg::ArrayReg, te::TimeEvolution)
    st = state(reg)
    @inbounds for j in 1:size(st, 2)
        v = view(st, :, j)
        Ks = arnoldi(te.H, v; tol=te.tol)
        expv!(v, te.dt, Ks)
    end
    return reg
end

cache_key(te::TimeEvolution) = (te.dt, cache_key(te.H))

# parametric interface
niparams(::Type{<:TimeEvolution}) = 1
getiparams(x::TimeEvolution) = x.dt
setiparams!(r::TimeEvolution, param::Real) = (r.dt = param; r)

function Base.:(==)(lhs::TimeEvolution, rhs::TimeEvolution)
    return lhs.H == rhs.H && lhs.dt == rhs.dt
end

function Base.adjoint(te::TimeEvolution)
    return TimeEvolution(te.H, adjoint(te.dt); tol=te.tol)
end
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.dt, tol=te.tol)

function YaoBase.isunitary(te::TimeEvolution)
    iszero(imag(te.dt)) || return false
    return true
end
