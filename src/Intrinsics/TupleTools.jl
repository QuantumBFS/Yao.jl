# The following is copied from Jutho/TupleTools
import Base: sort, sortperm, tail, diff

@inline _deleteat(t::Tuple, i::Int) = i == 1 ? tail(t) : (t[1], _deleteat(tail(t), i-1)...)
@inline _deleteat(t::Tuple{}, i::Int) = throw(BoundsError(t, i))

@inline _deleteat(t::Tuple, I::Tuple{Int}) = _deleteat(t, I[1])
@inline _deleteat(t::Tuple, I::Tuple{Int,Int,Vararg{Int}}) = _deleteat(_deleteat(t, I[1]), tail(I)) # assumes sorted from big to small

"""
    sort(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple
Sorts the tuple `t`.
"""
sort(t::Tuple; lt=isless, by=identity, rev::Bool=false) = _sort(t, lt, by, rev)
@inline function _sort(t::Tuple, lt=isless, by=identity, rev::Bool=false)
    i = 1
    if rev
        for k = 2:length(t)
            if lt(by(t[i]), by(t[k]))
                i = k
            end
        end
    else
        for k = 2:length(t)
            if lt(by(t[k]), by(t[i]))
                i = k
            end
        end
    end
    return (t[i], _sort(_deleteat(t, i), lt, by, rev)...)
end
@inline _sort(t::Tuple{Any}, lt=isless, by=identity, rev::Bool=false) = t

"""
    sortperm(t::Tuple; lt=isless, by=identity, rev::Bool=false) -> ::Tuple
Computes a tuple that contains the permutation required to sort `t`.
"""
sortperm(t::Tuple; lt=isless, by=identity, rev::Bool=false) = _sortperm(t, lt, by, rev)
_sortperm(t::Tuple{}, lt=isless, by=identity, rev::Bool=false) = ()
@inline function _sortperm(t::Tuple, lt=isless, by=identity, rev::Bool=false)
    i::Int = 1
    if rev
        for k = 2:length(t)
            if lt(by(t[i]), by(t[k]))
                i = k
            end
        end
    else
        for k = 2:length(t)
            if lt(by(t[k]), by(t[i]))
                i = k
            end
        end
    end
    r = _sortperm(_deleteat(t, i), lt, by, rev)
    return (i, ishift(r, i, +1)...)
end
@inline _sortperm(t::Tuple{Any}, lt=isless, by=identity, rev::Bool=false) = (1,)

@inline diff(t::NTuple) = t[2:end].-t[1:end-1]
