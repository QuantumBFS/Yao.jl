YaoAPI.DensityMatrix{D}(state::AbstractMatrix{T}) where {T,D} = DensityMatrix{D,T,typeof(state)}(state)
YaoAPI.DensityMatrix(state::AbstractMatrix{T}; nlevel=2) where T = DensityMatrix{nlevel}(state)

"""
    state(ρ::DensityMatrix) -> Matrix

Return the raw state of density matrix `ρ`.
"""
state(ρ::DensityMatrix) = ρ.state
Base.copy(ρ::DensityMatrix{D}) where D = DensityMatrix{D}(copy(ρ.state))
Base.similar(ρ::DensityMatrix{D}) where {D} = DensityMatrix{D}(similar(ρ.state))
Base.:(==)(ρ::DensityMatrix, σ::DensityMatrix) = nlevel(ρ) == nlevel(σ) && ρ.state == σ.state
Base.isapprox(ρ::DensityMatrix, σ::DensityMatrix; kwargs...) = nlevel(ρ) == nlevel(σ) && isapprox(ρ.state, σ.state; kwargs...)

YaoAPI.nqubits(ρ::DensityMatrix) = nqudits(ρ)
YaoAPI.nqudits(ρ::DensityMatrix{D}) where {D} = logdi(size(state(ρ), 1), D)
YaoAPI.nactive(ρ::DensityMatrix) = nqudits(ρ)
nbatch(::DensityMatrix) = NoBatch()
chstate(::DensityMatrix{D}, state) where D = DensityMatrix{D}(state)

"""
    rand_density_matrix([T=ComplexF64], n::Int; nlevel::Int=2, pure::Bool=false)

Generate a random density matrix by partial tracing half of the pure state.

!!! note

    The generated density matrix is not strict hermitian due to rounding error.
    If you need to check hermicity, do not use `ishermitian` consider using
    `isapprox(dm.state, dm.state')` or explicit mark it as `Hermitian`.
"""
function rand_density_matrix(n::Int; nlevel::Int=2, pure::Bool=false)
    return rand_density_matrix(ComplexF64, n; nlevel, pure)
end

function rand_density_matrix(::Type{T}, n::Int; nlevel::Int=2, pure::Bool=false) where T
    return pure ? density_matrix(rand_state(T, n; nlevel)) :
                  density_matrix(rand_state(T, 2n; nlevel), n+1:2n)
end

completely_mixed_state(n::Int; nlevel::Int=2) = completely_mixed_state(ComplexF64, n; nlevel)

function completely_mixed_state(::Type{T}, n::Int; nlevel::Int=2) where T
    return DensityMatrix{nlevel}(Matrix(IMatrix{T}(nlevel^n)))
end

# Move this to YaoAPI and dispatch on `AbstractRegister{D}`?
# Could then remove from YaoArrayRegister/src/register.jl and here
qubit_type(::DensityMatrix{2}) = "qubits"
qubit_type(::DensityMatrix) = "qudits"

function Base.show(io::IO, dm::DensityMatrix{D,T,MT}) where {D,T,MT}
    print(io, "DensityMatrix{$D, $T, $(nameof(MT))...}")
    print(io, "\n    active $(qubit_type(dm)): ", nactive(dm), "/", nqudits(dm))
    print(io, "\n    nlevel: ", nlevel(dm))
end

# Density matrices are hermitian
Base.adjoint(dm::DensityMatrix) = dm
LinearAlgebra.ishermitian(dm::DensityMatrix) =  true

function YaoAPI.density_matrix(reg::ArrayReg, qubits)
    freg = focus!(copy(reg), qubits)
    return density_matrix(freg)
end
function YaoAPI.density_matrix(dm::DensityMatrix, locs)
    n = nqudits(dm)
    @assert_locs_safe n (locs...,)
    return partial_tr(dm, setdiff(1:n, locs))
end
YaoAPI.density_matrix(reg::ArrayReg{D}) where D = DensityMatrix{D}(reg.state * reg.state')
YaoAPI.density_matrix(rho::DensityMatrix) = copy(rho)

YaoAPI.tracedist(dm1::DensityMatrix{D}, dm2::DensityMatrix{D}) where {D} = trace_norm(dm1.state .- dm2.state)

"""
    is_density_matrix(dm::AbstractMatrix; kw...)

Test if given matrix is a density matrix. The keyword
is the same as `isapprox`. See also `isapprox`.
"""
function is_density_matrix(dm::AbstractMatrix; kw...)
    return isapprox(tr(dm), 1.0; kw...) &&
        isapprox(dm, dm';kw...) &&
        isposdef(Hermitian(dm))
end

# TODO: use batch_broadcast in the future
"""
    probs(ρ) -> Vector

Returns the probability distribution from a density matrix `ρ`.
"""
YaoAPI.probs(m::DensityMatrix) = real.(diag(m.state))

function YaoAPI.fidelity(m::DensityMatrix, n::DensityMatrix)
    return density_matrix_fidelity(m.state, n.state)
end

function YaoAPI.purify(r::DensityMatrix{D}; num_env::Int = nactive(r)) where {D}
    Ne = D ^ num_env
    Ns = size(r.state, 1)
    R, U = eigen!(r.state)
    state = view(U, :, Ns-Ne+1:Ns) .* sqrt.(abs.(view(R, Ns-Ne+1:Ns)'))
    return ArrayReg{D}(state)
end

# obtaining matrix from Yao.DensityMatrix
LinearAlgebra.Matrix(d::DensityMatrix) = d.state

function zero_state_like(dm::DensityMatrix{D,T}, n::Int) where {D,T}
    state = similar(dm.state, D^n, D^n)   # NOTE: does not preserve adjoint
    fill!(state,zero(T))
    state[1:1,1:1] .= Ref(one(T))  # broadcast to make it GPU compatible.
    return DensityMatrix{D}(state)
end

"""
    von_neumann_entropy(rho) -> Real

Return the von-Neumann entropy for the input density matrix:

```math
-{\\rm Tr}(\\rho\\ln\\rho)
```
"""
von_neumann_entropy(dm::DensityMatrix) = von_neumann_entropy(Matrix(dm))
function von_neumann_entropy(dm::AbstractMatrix)
    p = max.(eigvals(dm), eps(real(eltype(dm))))
    return von_neumann_entropy(p)
end
von_neumann_entropy(v::AbstractVector) = -sum(x->x*log(x), v)

function mutual_information(dm::DensityMatrix, part1, part2)
    n = nqudits(dm)
    @assert_locs_safe n vcat(part1, part2)
    return von_neumann_entropy(density_matrix(dm, part1)) + von_neumann_entropy(density_matrix(dm, part2)) - 
        von_neumann_entropy(length(part1) + length(part2) == n ? dm : density_matrix(dm, part1 ∪ part2))
end

"""
    relative_entropy(rho1, rho2) -> Real

The relative entropy between two density matrices ``\\rho_1`` and ``\\rho_2`` is defined as:
```math
S(\\rho_1||\\rho_2) = \\rho_1\\ln\\rho_1 - \\rho_1\\ln\\rho_2,
```
which is equivalent to subtracting the cross entropy ``S(\\rho_1, \\rho_2)``, by the entropy of ``\\rho_1``.
"""
function relative_entropy(dm1::DensityMatrix, dm2::DensityMatrix)
    - von_neumann_entropy(dm1) + cross_entropy(dm1, dm2)
end

"""
    cross_entropy(rho1, rho2) -> Real

The cross entropy between two density matrices ``\\rho_1`` and ``\\rho_2`` is defined as:
```math
S(\\rho_1, \\rho_2) = - \\rho_1\\ln\\rho_2.
```
"""
function cross_entropy(dm1::DensityMatrix, dm2::DensityMatrix)
    - real(sum(transpose(dm1.state) .* log(dm2.state)))
end

function YaoAPI.partial_tr(dm::DensityMatrix{D,T}, locs) where {D,T}
    locs = Tuple(locs)
    nbits = nqudits(dm)
    @assert_locs_safe nbits (locs...,)
    m = nbits-length(locs)
    strides = ntuple(i->D^(i-1), nbits)
    out_strides = ntuple(i->D^(i-1), m)
    remainlocs = (setdiff(1:nbits, locs)...,)
    remain_strides = map(i->strides[i], remainlocs)
    trace_strides = ntuple(i->strides[locs[i]], length(locs))
    state = similar(dm.state, D^m, D^m)   # NOTE: does not preserve adjoint
    fill!(state, zero(T))
    partial_tr!(Val{D}(), state, dm.state, trace_strides, out_strides, remain_strides)
    return DensityMatrix{D}(state)
end

@generated function partial_tr!(::Val{D}, out::AbstractMatrix, dm::AbstractMatrix, trace_strides::NTuple{K,Int}, out_strides::NTuple{M,Int}, remain_strides::NTuple{M,Int}) where {D,K,M}
    quote
        sumc = length(remain_strides) == 0 ? 1 : 1 - sum(remain_strides)
        suma = length(out_strides) == 0 ? 1 : 1 - sum(out_strides)
        Base.Cartesian.@nloops($M, i, d->1:$D,
                d->(@inbounds sumc += i_d*remain_strides[d]; @inbounds suma += i_d*out_strides[d]), # PRE
                d->(@inbounds sumc -= i_d*remain_strides[d]; @inbounds suma -= i_d*out_strides[d]), # POST
                begin # BODY
                    sumd = length(remain_strides) == 0 ? 1 : 1 - sum(remain_strides)
                    sumb = length(out_strides) == 0 ? 1 : 1 - sum(out_strides)
                    Base.Cartesian.@nloops($M, j, d->1:$D,
                        d->(@inbounds sumd += j_d*remain_strides[d]; @inbounds sumb += j_d*out_strides[d]), # PRE
                        d->(@inbounds sumd -= j_d*remain_strides[d]; @inbounds sumb -= j_d*out_strides[d]), # POST
                        begin
                            sume = length(trace_strides) == 0 ? 1 : 1 - sum(trace_strides)
                            Base.Cartesian.@nloops($K, k, d->1:$D,
                                d->(@inbounds sume += k_d*trace_strides[d]), # PRE
                                d->(@inbounds sume -= k_d*trace_strides[d]), # POST
                                @inbounds out[suma, sumb] += dm[sumc+sume-1, sumd+sume-1]
                                )
                        end)
                end)

    end
end

"""
$(TYPEDSIGNATURES)
"""
function Base.join(r0::DensityMatrix{D}, rs::DensityMatrix{D}...) where {D}
    st = kron(state(r0), state.(rs)...)
    return DensityMatrix{D}(st)
end
