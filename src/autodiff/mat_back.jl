export mat_back!, mat_back
############### Primitive
"""
The matrix gradient of a rotation block.
"""
@inline function rotgrad(::Type{T}, rb::RotationGate{N}) where {N,T}
    -sin(rb.theta / 2) / 2 * IMatrix{1 << N}() + im / 2 * cos(rb.theta / 2) * conj(mat(T, rb.block))
end

function mat_back!(::Type{T}, rb::RotationGate{N,RT}, adjy, collector) where {T,N,RT}
    pushfirst!(collector, projection(rb.theta, sum(adjy .* rotgrad(T, rb))))
end

function mat_back!(::Type{T}, rb::TimeEvolution{N}, adjy, collector) where {N,T}
    pushfirst!(collector, projection(rb.dt, sum(im .* adjy .* conj.(mat(T, rb.H) * mat(T, rb)))))
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

function mat_back!(::Type{T}, rb::PutBlock{N,C,RT}, adjy, collector) where {T,N,C,RT}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, N, (), (), mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::Concentrator{N}, adjy, collector) where {T,N}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, N, (), (), mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::CachedBlock, adjy, collector) where {T}
    mat_back!(T, content(rb), adjy, collector)
end

function mat_back!(::Type{T}, rb::Daggered, adjy, collector) where {T}
    mat_back!(T, content(rb), adjy', collector)
end

function mat_back!(::Type{T}, rb::ControlBlock{N,C,RT}, adjy, collector) where {T,N,C,RT}
    nparameters(rb) == 0 && return collector
    adjm = adjcunmat(adjy, N, rb.ctrl_locs, rb.ctrl_config, mat(T, content(rb)), rb.locs)
    mat_back!(T, content(rb), adjm, collector)
end

function mat_back!(::Type{T}, rb::ChainBlock{N}, adjy, collector) where {T,N}
    np = nparameters(rb)
    np == 0 && return collector
    length(rb) == 1 && return mat_back!(T, rb[1], adjy, collector)

    mi = mat(T, rb[1])
    cache = Any[mi]
    for b in rb[2:end-1]
        mi = mat(T, b) * mi
        push!(cache, mi)
    end
    adjb = adjy * cache[end]'
    for ib in length(rb):-1:1
        b = rb[ib]
        #adjb = ib==1 ? adjy : adjy*cache[ib]'
        mat_back!(T, b, adjb, collector)
        ib != 1 && (adjb = mat(T, b)' * adjb * mat(T, rb[ib-1]))
    end
    return collector
end

function mat_back!(::Type{T}, rb::KronBlock{N}, adjy, collector) where {T,N}
    nparameters(rb) == 0 && return collector
    mat_back!(T, chain(N, [put(loc => rb[loc]) for loc in rb.locs]), adjy, collector)
    return collector
end

function mat_back!(::Type{T}, rb::Add{N}, adjy, collector) where {T,N}
    nparameters(rb) == 0 && return collector
    for b in subblocks(rb)[end:-1:1]
        mat_back!(T, b, adjy, collector)
    end
    return collector
end

function mat_back!(::Type{T}, rb::Scale{N}, adjy, collector) where {T,N}
    np = nparameters(rb)
    np == 0 && return collector
    mat_back!(T, content(rb), factor(rb) * adjy, collector)
    return collector
end

"""
    mat_back([::Type{T}, ]block::AbstractBlock, adjm::AbstractMatrix) -> Vector

The backward function of `mat`. Returns the gradients of parameters.
"""
mat_back(block::AbstractBlock, adjm::AbstractMatrix) = mat_back!(ComplexF64, block, adjm, [])
mat_back(::Type{T}, block::AbstractBlock, adjm::AbstractMatrix) where {T} =
    mat_back!(T, block, adjm, [])
