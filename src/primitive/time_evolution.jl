using ExponentialUtilities, YaoArrayRegister

export TimeEvolution, time_evolve

"""
    TimeEvolution{N, TT, GT} <: PrimitiveBlock{N}

TimeEvolution, where GT is block type. input matrix should be hermitian.

!!!note:
    `TimeEvolution` contructor check hermicity of the input block by default, but sometimes it can be slow. Turn off the check manually by specifying optional parameter `check_hermicity = false`.
"""
mutable struct TimeEvolution{N,Tt,HT<:AbstractBlock{N}} <: PrimitiveBlock{N}
    H::HT
    dt::Tt
    tol::Float64

    function TimeEvolution(
        H::TH,
        dt::Tt;
        tol::Real = 1e-7,
        check_hermicity::Bool = true,
    ) where {N,Tt,TH<:AbstractBlock{N}}
        (check_hermicity && !ishermitian(H)) &&
            error("Time evolution Hamiltonian has to be a Hermitian")
        return new{N,Tt,TH}(H, dt, Float64(tol))
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
time_evolve(M::AbstractBlock, dt; kwargs...) = TimeEvolution(M, dt; kwargs...)
time_evolve(dt; kwargs...) = @λ(M -> time_evolve(M, dt; kwargs...))

content(te::TimeEvolution) = te.H
chcontent(te::TimeEvolution, blk::AbstractBlock) = time_evolve(blk, te.dt; tol = te.tol)

function mat(::Type{T}, te::TimeEvolution{N}) where {T,N}
    return exp(-im * T(te.dt) * Matrix(mat(T, te.H)))
end

struct BlockMap{T,GT<:AbstractBlock} <: AbstractArray{T,2}
    block::GT
    BlockMap(::Type{T}, block::GT) where {T,GT<:AbstractBlock} = new{T,GT}(block)
end

Base.size(bm::BlockMap{T,GT}, i::Int) where {T,N,GT<:AbstractBlock{N}} =
    0 < i <= 2 ? 1 << N : DimensionMismatch("")
Base.size(bm::BlockMap{T,GT}) where {T,N,GT<:AbstractBlock{N}} = (L = 1 << N; (L, L))
LinearAlgebra.ishermitian(bm::BlockMap) = ishermitian(bm.block)

function LinearAlgebra.mul!(y::AbstractVector, A::BlockMap, x::AbstractVector)
    copyto!(y, x)
    apply!(ArrayReg(y), A.block)
    return y
end

function apply!(reg::ArrayReg{B,T}, te::TimeEvolution) where {B,T}
    st = state(reg)
    dt = real(te.dt) == 0 ? imag(te.dt) : -im * te.dt
    A = BlockMap(T, te.H)
    @inbounds for j in 1:size(st, 2)
        v = view(st, :, j)
        Ks = arnoldi(A, v; tol = te.tol, ishermitian = true, opnorm = 1.0)
        expv!(v, dt, Ks)
    end
    return reg
end

cache_key(te::TimeEvolution) = (te.dt, cache_key(te.H))

# parametric interface
niparams(::Type{<:TimeEvolution}) = 1
getiparams(x::TimeEvolution) = x.dt
setiparams!(r::TimeEvolution, param::Number) = (r.dt = param; r)

function Base.:(==)(lhs::TimeEvolution, rhs::TimeEvolution)
    return lhs.H == rhs.H && lhs.dt == rhs.dt
end

function Base.adjoint(te::TimeEvolution)
    return TimeEvolution(te.H, -adjoint(te.dt); tol = te.tol)
end
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.dt, tol = te.tol)

function YaoBase.isunitary(te::TimeEvolution)
    iszero(imag(te.dt)) || return false
    return true
end
