# A Simple Computational Algebra System

# scale
Base.:(-)(x::AbstractBlock{N}) where {N} = Scale(Val(-1), x)
Base.:(-)(x::Scale{Val{-1}}) = content(x)
Base.:(-)(x::Scale{Val{S}}) where S = Scale(Val(-S), content(x))
Base.:(-)(x::Scale) = Scale(-x.alpha, content(x))
Base.:(+)(x::AbstractBlock) = x

Base.:(*)(x::AbstractBlock, α::Number) = α * x

# NOTE: ±,±im should be identical
Base.:(*)(α::Val{S}, x::AbstractBlock) where S = Scale(α, x)

function Base.:(*)(α::T, x::AbstractBlock) where T <: Number
    return α ==  one(T) ? x                 :
    α == -one(T) ? Scale(Val(-1), x)   :
    α ==      im ? Scale(Val(im), x)        :
    α ==     -im ? Scale(Val(-im), x)       :
    Scale(α, x)
end

Base.:(*)(α::T, x::Scale) where {T <: Number} = α == one(T) ? x : Scale(x.alpha * α, content(x))
Base.:(*)(α::T, x::Scale{Val{S}}) where {T <: Number, S} = α * S * content(x)

Base.:(*)(α::Val{S}, x::Scale) where S = (S * x.alpha) * content(x)
Base.:(*)(α::Val{S1}, x::Scale{Val{S2}}) where {S1, S2} = (S1 * S2) * content(x)

Base.:(*)(x::Scale, y::Scale) = (x.alpha * y.alpha) * (content(x) * content(y))
Base.:(*)(x::Scale{Val{S1}}, y::Scale{Val{S2}}) where {S1, S2} = (S1 * S2) * (content(x) * content(y))
Base.:(*)(x::Scale, y::Scale{Val{S}}) where S = (x.alpha * S) * (content(x) * content(y))
Base.:(*)(x::Scale{Val{S}}, y::Scale) where S = (S * y.alpha) * (content(x) * content(y))
Base.:(*)(x::Scale, y::AbstractBlock) = x.alpha * chain(y, content(x))
Base.:(*)(y::AbstractBlock, x::Scale) = x.alpha * chain(content(x), y)

Base.:(+)(xs::AbstractBlock...) = Sum(xs...)
Base.:(*)(xs::AbstractBlock...) = chain(Iterators.reverse(xs)...)
Base.:(/)(A::AbstractBlock, x::Number) = (1/x)*A
# reduce
Base.sum(a::AbstractBlock{N}, blocks::AbstractBlock{N}...) where N = Sum(a, blocks...)
Base.prod(a::AbstractBlock{N}, blocks::AbstractBlock{N}...) where N = chain(Iterators.reverse(blocks)..., a)

Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Sum(lhs, -rhs)
Base.:(^)(x::AbstractBlock, n::Int) = chain((copy(x) for k in 1:n)...)

"""
circuit optimisation
"""
module Optimise
using SimpleTraits
using YaoBlocks, YaoBlocks.ConstGate

export is_pauli, IsPauliGroup

"""
    IsPauliGroup{X}

Trait to check if `X` is an element of Pauli group.
"""
@traitdef IsPauliGroup{X}
IsPauliGroup(x) = IsPauliGroup{typeof(x)}()

"""
    is_pauli(x)

Check if `x` is an element of pauli group.

!!! note
    this function is just a binding of `SimpleTraits.istrait`, it will not work
    if the type is not registered as a trait with `@traitimpl`.
"""
is_pauli(x::T) where T = SimpleTraits.istrait(IsPauliGroup{T})
is_pauli(xs...) = all(is_pauli, xs)

for G in [:I2, :X, :Y, :Z]
    ImG = Symbol(:Im, G)
    nImG = Symbol(:nIm, G)
    nG = Symbol(:n, G)

    @eval const $ImG = im * $G
    @eval const $nImG = -im * $G
    @eval const $nG = -$G

    @eval @traitimpl IsPauliGroup{typeof($G)}
    @eval @traitimpl IsPauliGroup{typeof($ImG)}
    @eval @traitimpl IsPauliGroup{typeof($nImG)}
    @eval @traitimpl IsPauliGroup{typeof($nG)}
end

export merge_pauli
merge_pauli(x) = x
merge_pauli(x::AbstractBlock, y::AbstractBlock) = x * y

function merge_pauli(ex::ChainBlock{1})
    L = length(ex)
    new_ex = chain(1)

    # find all contiguous pauli and merge them
    # note we need to iterate in inverse order
    iterm = L
    while iterm > 0
        if iterm > 1 && is_pauli(ex[iterm], ex[iterm-1])
            pushfirst!(new_ex, merge_pauli(ex[iterm], ex[iterm-1]))
            iterm = iterm - 2
        else
            # search next
            pushfirst!(new_ex, ex[iterm])
            iterm -= 1
        end
    end
    return new_ex
end

merge_pauli(::XGate, ::YGate) = ImZ
merge_pauli(::XGate, ::ZGate) = -ImY
merge_pauli(::YGate, ::XGate) = -ImZ
merge_pauli(::YGate, ::ZGate) = ImX
merge_pauli(::ZGate, ::XGate) = ImY
merge_pauli(::ZGate, ::YGate) = nImX

for G in [:X, :Y, :Z]
    GT = Symbol(G, :Gate)

    @eval merge_pauli(::I2Gate, x::$GT) = x
    @eval merge_pauli(x::$GT, ::I2Gate) = x
    @eval merge_pauli(::$GT, ::$GT) = I2
end

merge_pauli(::I2Gate, ::I2Gate) = I2

export eliminate_nested
eliminate_nested(ex::AbstractBlock) = ex

# TODO: eliminate nested expr e.g chain(X, chain(X, Y))
function eliminate_nested(ex::T) where {T <: Union{ChainBlock, Sum}}
    _flatten(x) = (x, )
    _flatten(x::T) = subblocks(x)

    isone(length(ex)) && return first(subblocks(ex))
    return chsubblocks(ex, Iterators.flatten(map(_flatten, subblocks(ex))))
end

# temporary utils
_unscale(x::AbstractBlock) = x
_unscale(x::Scale) = content(x)
merge_alpha(alpha, x::AbstractBlock) = alpha
merge_alpha(alpha, x::Scale) = alpha * x.alpha
merge_alpha(alpha, x::Scale{Val{S}}) where S = alpha * S

# since we don't have T in blocks, this is a workaround
# to get correct identity in type stable term
merge_alpha(::Nothing, x::Scale) = x.alpha
merge_alpha(::Nothing, x::Scale{Val{S}}) where S = S
merge_alpha(::Nothing, x::AbstractBlock) = nothing

merge_scale(ex::AbstractBlock) = ex

# a simple function to find one for Val and Number
_one(x) = one(x)
_one(::Type{Val{S}}) where S = one(S)
_one(::Val{S}) where S = one(S)

export merge_scale

function merge_scale(ex::Union{Scale{S, N}, ChainBlock{N}}) where {S, N}
    alpha = nothing
    for each in subblocks(ex)
        alpha = merge_alpha(alpha, each)
    end
    ex = chsubblocks(ex, map(_unscale, subblocks(ex)))
    if alpha === nothing
        return ex
    else
        return alpha * ex
    end
end

export combine_similar

combine_similar(ex::AbstractBlock) = ex

combine_alpha(alpha, x) = alpha
combine_alpha(alpha, x::AbstractBlock) = alpha + 1
combine_alpha(alpha, x::Scale) = alpha + x.alpha
combine_alpha(alpha, x::Scale{Val{S}}) where S = alpha + S

function combine_similar(ex::Sum{N}) where N
    table = zeros(Bool, length(ex))
    list = []; p = 1
    while p <= length(ex)
        if table[p] == true
            # checked term, skip
            p += 1
        else
            # check similar term
            term = ex[p]
            table[p] = true # mark it in the table
            alpha = 1
            for (k, each) in enumerate(ex)
                if table[k] == true # checked term, skip
                    continue
                else
                    # check if unscaled term is the same
                    # merge them if they are
                    if _unscale(term) == _unscale(each)
                        alpha = combine_alpha(alpha, each)
                        # mark checked term in the table
                        table[k] = true
                    end
                end
            end

            # eliminate zeros
            if alpha != 0
                alpha = imag(alpha) == 0 ? real(alpha) : alpha
                alpha = isinteger(alpha) ? Integer(alpha) : alpha
                push!(list, alpha * term)
            end
        end
    end

    if isempty(list)
        return Sum{N}(())
    else
        return Sum(list...)
    end
end

export simplify

const __default_simplification_rules__ = Function[
    merge_pauli,
    eliminate_nested,
    merge_scale,
    combine_similar]

# Inspired by MasonPotter/Symbolics.jl
"""
    simplify(block[; rules=__default_simplification_rules__])

Simplify a block tree accroding to given rules, default to use
[`__default_simplification_rules__`](@ref).
"""
function simplify(ex::AbstractBlock; rules=__default_simplification_rules__)
    out1 = simplify_pass(rules, ex)
    out2 = simplify_pass(rules, out1)
    counter = 1
    while (out1 isa AbstractBlock) && (out2 isa AbstractBlock) && (out2 != out1)
        out1 = simplify_pass(rules, out2)
        out2 = simplify_pass(rules, out1)
        counter += 1
        if counter > 1000
            @warn "possible infinite loop in simplification rules. Breaking"
            return out2
        end
    end
    return out2
end

function simplify_pass(rules, ex)
    ex = chsubblocks(ex, map(x->simplify_pass(rules, x), subblocks(ex)))

    for rule in rules
        ex = rule(ex)
    end
    return ex
end


end
