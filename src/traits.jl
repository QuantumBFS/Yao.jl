using LinearAlgebra, YaoArrayRegister
import YaoBase: @interface

abstract type IteratorWrapper{It} end

Base.iterate(it::IteratorWrapper) = iterate(it.it)
Base.iterate(it::IteratorWrapper, st) = iterate(it.it, st)
Base.IteratorSize(it::IteratorWrapper) = Base.IteratorSize(it.it)
Base.IteratorEltype(it::IteratorWrapper) = Base.IteratorEltype(it.it)
Base.eltype(it::IteratorWrapper) = eltype(it.it)
Base.length(it::IteratorWrapper) = length(it.it)
Base.size(it::IteratorWrapper) = size(it.it)
Base.lastindex(it::IteratorWrapper) = lastindex(it.it)
Base.getindex(it::IteratorWrapper, k) = getindex(it.it, k)
Base.IndexStyle(it::IteratorWrapper) = Base.IndexStyles(it.it)

function Base.:(==)(it_a::IteratorWrapper, it_b)
    for (a, b) in zip(it_a, it_b)
        if a != b
            return false
        end
    end
    return true
end

Base.:(==)(it_a, it_b::IteratorWrapper) = it_b == it_a
Base.:(==)(it_a::IteratorWrapper, it_b::IteratorWrapper) =
    invoke(Base.:(==), Tuple{IteratorWrapper, Any}, it_a, it_b)

function Base.show(io::IO, it::IteratorWrapper)
    summary(io, it)
    if get(io, :compact, false)
        v = collect(it)
        if length(v) > 4
            for k in 1:2
                println(io, " ", v[k])
            end
            println(" ⋮")
            for k in lastindex(v):-1:lastindex(v)-2
                println(io, " ", v[k])
            end
        else
            foreach(x->println(io, " ", x), v)
        end
    else
        for each in it
            println(io, " ", each)
        end
    end
    return
end

"""
    occupied_locations(blk)

Returns an iterator of occupied locations of a given block.
"""
@interface occupied_locations(x) = OccupiedLocationsIt(OccupiedLocations(x))

"""
    subblocks(composite_block)

Return an iterator of sub-blocks contained by a composite block.
"""
@interface subblocks(x) = SubBlockIt(SubBlocks(x))

"""
    SubBlockIt{It} <: IteratorWrapper{It}

A wrapper type for sub-block iterators to make the printing looks better, while
no extra allocation is created.

    SubBlockIt(itr)

Create a [`SubBlockIt`](@ref) with an iterator.
"""
struct SubBlockIt{It} <: IteratorWrapper{It}
    it::It
end

"""
    SubBlockIt()

Create an empty [`SubBlockIt`](@ref).
"""
SubBlockIt() = SubBlockIt(())

Base.summary(io::IO, it::SubBlockIt) = println(io, "SubBlockIt{...}")

"""
    OccupiedLocationsIt{It} <: IteratorWrapper{It}

A wrapper type for pretty printing occupied locations.

    OccupiedLocationsIt(itr)

Create an [`OccupiedLocationsIt`](@ref) with an iterator.
"""
struct OccupiedLocationsIt{It} <: IteratorWrapper{It}
    it::It
end

Base.summary(io::IO, it::OccupiedLocationsIt) = println(io, "OccupiedLocationsIt{...}")

function Base.show(io::IO, it::OccupiedLocationsIt)
    summary(io, it)
    v = sort!(collect(it))
    if get(io, :compact, false) && length(v) > 4
        for k in 1:2
            println(io, " ", v[k])
        end
        println(" ⋮")
        for k in lastindex(v)-1:lastindex(v)
            println(io, " ", v[k])
        end
    else
        foreach(x->println(io, " ", x), v)
    end
    return
end

# abstract type MatrixTrait end
# struct HasMatrix{N, T} end
# struct MatrixUnkown end
#
# # NOTE: most blocks have matrix, use `HasMatrix` by default.
# #       this will error when `mat` is not defined anyway, no worries.
# MatrixTrait(x::AbstractBlock) where T = HasMatrix{nqubits(x), datatype(x)}()
#
# apply!(r::AbstractRegister, b::AbstractBlock) = apply!(MatrixTrait(b), r, b)
#
# function apply!(::HasMatrix, r::ArrayReg, b::AbstractBlock)
#     mul!(r.state, mat(b), r)
#     return r
# end
#
# function apply!(::HasMatrix, r::ArrayReg, b::AbstractBlock)
#     if applicable(mat, b)
#         mul!(r.state, mat(b), r)
#     else
#         throw(MethodError(apply!, (r, b)))
#     end
#     return r
# end
