using ExponentialUtilities, YaoArrayRegister

export TimeEvolution, time_evolve

"""
    TimeEvolution{N, TT, GT} <: PrimitiveBlock{N}

TimeEvolution, where GT is block type. input matrix should be hermitian.

!!!note:
    `TimeEvolution` contructor check hermicity of the input block by default, but sometimes it can be slow. Turn off the check manually by specifying optional parameter `check_hermicity = false`.
"""
mutable struct TimeEvolution{N, T, Tt, Hamilton <: AbstractBlock{N}} <: PrimitiveBlock{N}
    H::BlockMap{Complex{T}, Hamilton}
    dt::Tt
    tol::T

    function TimeEvolution(
        H::BlockMap{Complex{T}, TH},
        dt::Tt, tol::T; check_hermicity::Bool=true) where {N, Tt, T, TH <: AbstractBlock{N}}
        (check_hermicity && !ishermitian(H)) && error("Time evolution Hamiltonian has to be a Hermitian")
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
TimeEvolution(H::AbstractBlock, dt; tol::Real=1e-7, check_hermicity=true) =
    TimeEvolution(BlockMap(H), dt, tol, check_hermicity=check_hermicity)

TimeEvolution(M::BlockMap, dt; tol::Real, check_hermicity=true) =
    TimeEvolution(M, dt, tol, check_hermicity=check_hermicity)

time_evolve(M::BlockMap, dt; kwargs...) = TimeEvolution(M, dt; kwargs...)
time_evolve(M::AbstractBlock, dt; kwargs...) = TimeEvolution(M, dt; kwargs...)
time_evolve(dt; kwargs...) = @λ(M->time_evolve(M, dt; kwargs...))

function mat(::Type{T}, te::TimeEvolution{N}) where {T, N}
    A = Matrix{T}(te.H.block)
    return exp(-im*T(te.dt) * A)
end

function apply!(reg::ArrayReg, te::TimeEvolution)
    st = state(reg)
    dt = real(te.dt) == 0 ? imag(te.dt) : -im*te.dt
    @inbounds for j in 1:size(st, 2)
        v = view(st, :, j)
        Ks = arnoldi(te.H, v; tol=te.tol, ishermitian=true)
        expv!(v, dt, Ks)
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
    return TimeEvolution(te.H, -adjoint(te.dt); tol=te.tol)
end
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.dt, tol=te.tol)

function YaoBase.isunitary(te::TimeEvolution)
    iszero(imag(te.dt)) || return false
    return true
end
