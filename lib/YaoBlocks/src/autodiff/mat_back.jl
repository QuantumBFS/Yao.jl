export mat_back!, mat_back
############### Primitive
"""
The matrix gradient of a rotation block.
"""
@inline function rotgrad(::Type{T}, rb::RotationGate{D}) where {D,T}
    -sin(rb.theta / 2) / 2 * IMatrix{D^nqudits(rb)}() +
    im / 2 * cos(rb.theta / 2) * conj(mat(T, rb.block))
end

function mat_back!(::Type{T}, rb::RotationGate{D,RT}, adjy, collector) where {T,D,RT}
    pushfirst!(collector, projection(rb.theta, sum(adjy .* rotgrad(T, rb))))
end

function mat_back!(::Type{T}, rb::TimeEvolution, adjy, collector) where {T}
    pushfirst!(
        collector,
        projection(rb.dt, im * _sum_A_Bconj(adjy, mat(T, rb.H) * mat(T, rb))),
    )
end

#=
function mat_back!(::Type{T}, A::GeneralMatrixBlock, adjy, collector) where T
    for i in length(adjy):-1:1
        pushfirst!(collector, adjy[i])
    end
end
=#

function mat_back!(::Type{T}, rb::PhaseGate, adjy, collector) where {T}
    s = exp(-im * rb.theta)
    res = -1im * (adjy[1, 1] * s + adjy[2, 2] * s)
    pushfirst!(collector, projection(rb.theta, res))
end

function mat_back!(::Type{T}, rb::ShiftGate, adjy, collector) where {T}
    res = -1im * adjy[2, 2] * exp(-1im * rb.theta)
    pushfirst!(collector, projection(rb.theta, res))
end

######################## Composite
function mat_back!(::Type{T}, rb::AbstractBlock, adjy, collector) where {T}
    nparameters(rb) == 0 && return collector
    throw(MethodError(mat_back!, (T, rb, adjy, collector)))
end

function mat_back!(::Type{T}, rb::PutBlock{D,C,RT}, adjy, collector) where {T,D,C,RT}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, nqudits(rb), (), (), mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::Subroutine, adjy, collector) where {T}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, nqudits(rb), (), (), mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::CachedBlock, adjy, collector) where {T}
    mat_back!(T, content(rb), adjy, collector)
end

function mat_back!(::Type{T}, rb::Daggered, adjy, collector) where {T}
    mat_back!(T, content(rb), adjy', collector)
end

function mat_back!(::Type{T}, rb::ControlBlock, adjy, collector) where {T}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, nqudits(rb), rb.ctrl_locs, rb.ctrl_config, mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::ChainBlock{D}, adjy, collector) where {T,D}
    np = nparameters(rb)
    np == 0 && return collector
    length(rb) == 1 && return mat_back!(T, rb[1], adjy, collector)

    # cache the tape
    mi = mat(T, rb[1])
    cache = Any[mi]
    for b in rb[2:end-1]
        mi = mat(T, b) * mi
        push!(cache, mi)
    end
    adjb = adjy * cache[end]'
    for ib = length(rb):-1:1
        b = rb[ib]
        #adjb = ib==1 ? adjy : adjy*cache[ib]'
        mat_back!(T, b, adjb, collector)
        if ib != 1
            if adjb isa DenseMatrix
                adjb = apply!(ArrayReg{D}(apply!(ArrayReg{D}(adjb), b').state'), rb[ib-1]').state'
            else
                adjb = mat(T, b)' * adjb * mat(T, rb[ib-1])
            end
        end
    end
    return collector
end

_

function mat_back!(::Type{T}, rb::KronBlock, adjy, collector) where {T}
    nparameters(rb) == 0 && return collector
    mat_back!(T, chain(nqudits(rb), [put(loc => rb[loc]) for loc in rb.locs]), adjy, collector)
    return collector
end

function mat_back!(::Type{T}, rb::Add, adjy, collector) where {T}
    nparameters(rb) == 0 && return collector
    for b in subblocks(rb)[end:-1:1]
        mat_back!(T, b, adjy, collector)
    end
    return collector
end

function mat_back!(::Type{T}, rb::Scale, adjy, collector) where {T}
    np = nparameters(rb)
    np == 0 && return collector
    mat_back!(T, content(rb), factor(rb) * adjy, collector)
    if niparams(rb) > 0
        pushfirst!(collector, projection(rb.alpha, _sum_A_Bconj(adjy, mat(T, content(rb)))))
    end
    return collector
end

# ∑ A .* B*, A is mutated.
_sum_A_Bconj(A::AbstractMatrix, B::AbstractMatrix) = sum(A .* conj.(B))
function _sum_A_Bconj(A::OuterProduct, B::AbstractMatrix)
    res = conj(A.left' * (B * conj(A.right)))
    return ndims(res) != 0 ? sum(diag(res)) : res
end

"""
    mat_back([::Type{T}, ]block::AbstractBlock, adjm::AbstractMatrix) -> Vector

The backward function of `mat`. Returns the gradients of parameters.
"""
mat_back(block::AbstractBlock, adjm::AbstractMatrix{T}) where {T} =
    mat_back!(T, block, adjm, parameters_eltype(block)[])
mat_back(::Type{T}, block::AbstractBlock, adjm::AbstractMatrix) where {T} =
    mat_back!(T, block, adjm, parameters_eltype(block)[])
