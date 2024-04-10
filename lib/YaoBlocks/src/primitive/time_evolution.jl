export TimeEvolution, time_evolve

"""
    TimeEvolution{D, TT, GT} <: PrimitiveBlock{D}

TimeEvolution, where GT is block type. input matrix should be hermitian.

!!! note

    `TimeEvolution` contructor check hermicity of the input block by default,
    but sometimes it can be slow. Turn off the check manually by specifying
    optional parameter `check_hermicity = false`.
"""
mutable struct TimeEvolution{D,Tt,HT<:AbstractBlock{D}} <: PrimitiveBlock{D}
    H::HT
    dt::Tt
    tol::Float64

    function TimeEvolution(
        H::TH,
        dt::Tt;
        tol::Real = 1e-7,
        check_hermicity::Bool = true,
    ) where {D,Tt,TH<:AbstractBlock{D}}
        (check_hermicity && !ishermitian(H)) &&
            error("Time evolution Hamiltonian has to be a Hermitian")
        return new{D,Tt,TH}(H, dt, Float64(tol))
    end
end
nqudits(te::TimeEvolution) = nqudits(te.H)

"""
    time_evolve(H, dt[; tol=1e-7, check_hermicity=true])

Create a [`TimeEvolution`](@ref) block with Hamiltonian `H` and time step `dt`. The
`TimeEvolution` block will use Krylove based `expv` to calculate time propagation.
`TimeEvolution` block can also be used for
[imaginary time evolution](http://large.stanford.edu/courses/2008/ph372/behroozi2/)
if `dt` is complex.
Let ``H`` be a hamiltonian and ``t`` be a time, the matrix representation of `time_evolve(H, t)` is ``e^{-iHt}``.

### Arguments

- `H` the hamiltonian represented as an `AbstractBlock`.
- `dt`: the evolution duration (start time is zero).

### Keyword Arguments

- `tol::Real=1e-7`: error tolerance.
- `check_hermicity=true`: check hermicity or not.

### Examples

```jldoctest; setup=:(using Yao)
julia> time_evolve(kron(2, 1=>X, 2=>X), 0.1)
Time Evolution Δt = 0.1, tol = 1.0e-7
kron
├─ 1=>X
└─ 2=>X
```
"""
time_evolve(M::AbstractBlock, dt; kwargs...) = TimeEvolution(M, dt; kwargs...)
time_evolve(dt; kwargs...) = @λ(M -> time_evolve(M, dt; kwargs...))

content(te::TimeEvolution) = te.H
chcontent(te::TimeEvolution, blk::AbstractBlock) = time_evolve(blk, te.dt; tol = te.tol)

function mat(::Type{T}, te::TimeEvolution) where {T}
    return _exp((-im * T(te.dt)) .* mat(T, te.H))
end
_exp(m::AbstractMatrix) = exp(m)
_exp(m::SparseMatrixCSC) = exp(Matrix(m))

struct BlockMap{T,GT<:AbstractBlock} <: AbstractArray{T,2}
    block::GT
    BlockMap(::Type{T}, block::GT) where {T,GT<:AbstractBlock} = new{T,GT}(block)
end

Base.size(bm::BlockMap{T,GT}, i::Int) where {T,D,GT<:AbstractBlock{D}} =
    0 < i <= 2 ? D^nqudits(bm.block) : DimensionMismatch("")
Base.size(bm::BlockMap{T,GT}) where {T,D,GT<:AbstractBlock{D}} = (L = D^nqudits(bm.block); (L, L))
LinearAlgebra.ishermitian(bm::BlockMap) = ishermitian(bm.block)

function LinearAlgebra.mul!(y::AbstractVector, A::BlockMap{T,GT}, x::AbstractVector) where {T,D,GT<:AbstractBlock{D}}
    copyto!(y, x)
    apply!(ArrayReg{D}(y), A.block)
    return y
end

compatible_multiplicative_operand(::AbstractArray, source::AbstractArray) = source

function YaoAPI.unsafe_apply!(reg::AbstractArrayReg{D,T}, te::TimeEvolution) where {D,T}
    if isdiagonal(te.H)
        # `compatible_multiplicative_operand` is used to ensure GPU compatibility.
        reg.state .*= exp.((-im * te.dt) .* compatible_multiplicative_operand(reg.state, diag(mat(T, te.H))))
        return reg
    end
    st = state(reg)
    dt = real(te.dt) == 0 ? imag(te.dt) : -im * te.dt
    A = BlockMap(T, te.H)
    @inbounds for j = 1:size(st, 2)
        v = view(st, :, j)
        v_out, info = exponentiate(A, dt, v,
                                   tol=te.tol,
                                   krylovdim=min(1000, size(A,1)),
                                   ishermitian=true,
                                   eager=true,)
        # info.converged is 1 if it converged and 0 otherwise
        Bool(info.converged) || @warn "Application of $(typeof(te)) did not converge. error = $(info.normres) but tol=$(te.tol)"
        v .= v_out
    end
    return reg
end

cache_key(te::TimeEvolution) = (te.dt, cache_key(te.H))

# parametric interface
niparams(::Type{<:TimeEvolution}) = 1
getiparams(x::TimeEvolution) = x.dt
setiparams!(r::TimeEvolution, param::Number) = (r.dt = param; r)
setiparams(r::TimeEvolution, param::Number) =
    TimeEvolution(r.H, param; tol = r.tol, check_hermicity = false)

function Base.:(==)(lhs::TimeEvolution, rhs::TimeEvolution)
    return lhs.H == rhs.H && lhs.dt == rhs.dt
end

function Base.adjoint(te::TimeEvolution)
    return TimeEvolution(te.H, -adjoint(te.dt); tol = te.tol)
end
Base.copy(te::TimeEvolution) = TimeEvolution(te.H, te.dt, tol = te.tol)

YaoAPI.isdiagonal(te::TimeEvolution) = isdiagonal(te.H)
YaoAPI.isunitary(te::TimeEvolution) = iszero(imag(te.dt))

iparams_range(::TimeEvolution{D,T}) where {D,T} = ((typemin(T), typemax(T)),)

function unsafe_getindex(::Type{T}, te::TimeEvolution{D}, i::Integer, j::Integer) where {D,T}
    return apply!(ArrayReg{D}(BitBasis._onehot(T, D^nqudits(te), j+1)), te).state[i+1]
end
function unsafe_getcol(::Type{T}, te::TimeEvolution{D}, j::DitStr{D,L,TI}) where {D,T,L,TI<:Integer}
    map(x->DitStr{D,L,TI}(buffer(x)), basis(te)), statevec(apply!(ArrayReg{D}(BitBasis.onehot(T, j)), te))
end
function _getindex(te::TimeEvolution{D}, ::Colon, j::EntryTable{DitStr{D,L,TI},T}) where {D,L,TI<:Integer,T}
    EntryTable(map(x->DitStr{D,L,TI}(buffer(x)), basis(te)), YaoArrayRegister.matchtype(T, statevec(apply!(ArrayReg{D}(vec(j)), te))))
end
