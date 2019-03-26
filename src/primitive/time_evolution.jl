using ExponentialUtilities, YaoArrayRegister

export TimeEvolution

"""
    TimeEvolution{N, TT, GT} <: PrimitiveBlock{N, ComplexF64}

TimeEvolution, where GT is block type. input matrix should be hermitian.
"""
struct TimeEvolution{N, T, Hamilton <: AbstractBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    H::BlockMap{Complex{T}, Hamilton}
    dt::T
    tol::T
    is_itime::Bool

    function TimeEvolution(
        H::BlockMap{Complex{T}, TH},
        dt::T, tol::T,
        is_itime::Bool) where {N, T, TH <: AbstractBlock{N, Complex{T}}}
        # The time evolution Hamiltonian has to be a Hermitian
        ishermitian(H) || error("Time evolution Hamiltonian has to be a Hermitian")
        return new{N, T, TH}(H, dt, tol, is_itime)
    end
end

"""
    TimeEvolution(H, dt::Real[; tol::Real=1e-7, is_itime::Bool=false])

Create a [`TimeEvolution`](@ref) block with Hamiltonian `H` and time step `dt`. The
`TimeEvolution` block will use Krylove based `expv` to calculate time propagation.

Optional keywords are tolerance `tol` (default is `1e-7`)
`TimeEvolution` block can also be used for
[imaginary time evolution](http://large.stanford.edu/courses/2008/ph372/behroozi2/)
if `is_itime` is set to `true`.
"""
TimeEvolution(H::AbstractBlock, dt::Real; tol::Real=1e-7, is_itime::Bool=false) =
    TimeEvolution(BlockMap(H), dt, tol, is_itime)

TimeEvolution(M::BlockMap, dt::Real; tol::Real, is_itime::Bool=false) =
    TimeEvolution(M, dt, tol, is_itime)

function mat(te::TimeEvolution{N}) where N
    A = Matrix(mat(te.H.block))
    if te.is_itime
        return exp(te.dt * A)
    else
        return exp(-im * te.dt * A)
    end
end

function apply!(reg::ArrayReg, te::TimeEvolution)
    st = state(reg)
    τ = te.is_itime ? te.dt : -im * te.dt
    @inbounds for j in 1:size(st, 2)
        v = view(st, :, j)
        Ks = arnoldi(te.H, v; tol=te.tol)
        expv!(v, τ, Ks)
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
    nt = te.is_itime ? te.dt : -te.dt
    return TimeEvolution(te.H, nt; tol=te.tol, is_itime=te.is_itime)
end
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.dt, tol=te.tol)

function YaoBase.isunitary(te::TimeEvolution)
    te.is_itime && return false
    return true
end
