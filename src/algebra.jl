# A Simple Computational Algebra System

# scale
Base.:(-)(x::AbstractBlock{N, T}) where {N, T} = Scale(Val(-1), x)
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
Base.:(*)(x::Scale, y::AbstractBlock) = x.alpha * Prod(content(x), y)
Base.:(*)(y::AbstractBlock, x::Scale) = x.alpha * Prod(y, content(x))

Base.:(+)(xs::AbstractBlock...) = Sum(xs...)
Base.:(*)(xs::AbstractBlock...) = Prod(xs...)
Base.:(/)(A::AbstractBlock, x::Number) = (1/x)*A
# reduce
Base.sum(a::AbstractBlock{N, T}, blocks::AbstractBlock{N, T}...) where {N, T} = Sum(a, blocks...)
Base.prod(a::AbstractBlock{N, T}, blocks::AbstractBlock{N, T}...) where {N, T} = Prod(a, blocks...)

Base.:(-)(lhs::AbstractBlock, rhs::AbstractBlock) = Sum(lhs, -rhs)
Base.:(^)(x::AbstractBlock, n::Int) = Prod((copy(x) for k in 1:n)...)

for G in [:I2, :X, :Y, :Z]
    ImG = Symbol(:Im, G)
    nImG = Symbol(:nIm, G)
    nG = Symbol(:n, G)
    GGate = Symbol(G, :Gate)
    @eval const $ImG{T} = Scale{Val{im}, 1, T, $GGate{T}}
    @eval $ImG(::Type{T}) where T = Scale(Val(im), $G(T))

    @eval const $nImG{T} = Scale{Val{-im}, 1, T, $GGate{T}}
    @eval $nImG(::Type{T}) where T = Scale(Val(-im), $G(T))

    @eval const $nG{T} = Scale{Val{-1}, 1, T, $GGate{T}}
    @eval $nG(::Type{T}) where T = Scale(Val(-1), $G(T))
end


const PauliGroup{T} = Union{
    PauliGate{T}, nX{T}, nY{T}, nZ{T}, nI2{T},
    ImX{T}, ImY{T}, ImZ{T}, nImX{T}, nImY{T}, nImZ{T}, ImI2{T}, nImI2{T}}

merge_pauli(x) = x
merge_pauli(ex::Prod{1}) = merge_pauli(ex, ex.list...)

# Well, there should be some way to do this, but just
# too lazy to implement this pass
merge_pauli(ex::ChainBlock) = Prod(Iterators.reverse(subblocks(ex))...)

merge_pauli(ex::Prod{1}, blks::AbstractBlock...) = merge_pauli(ex, (), blks...)

merge_pauli(ex::Prod{1}, out::Tuple, a::AbstractBlock{1, T}, blks::AbstractBlock{1, T}...) where T =
    merge_pauli(ex, (out..., a), blks...)
merge_pauli(ex::Prod{1}, out::Tuple, a::PauliGroup{T}, blks::AbstractBlock{1, T}...) where T =
    merge_pauli(ex, (out..., a), blks...)
merge_pauli(ex::Prod{1}, out::Tuple, a::PauliGroup{T}, b::PauliGroup{T}, blks::AbstractBlock{1, T}...) where T =
    merge_pauli(ex, (out..., merge_pauli(a, b)), blks...)

merge_pauli(ex::Prod{N, T}, out::Tuple) where {N, T} = Prod(out...)
merge_pauli(ex::Prod{N, T}, out::Tuple{}) where {N, T} = IGate{N, T}()
merge_pauli(ex::Prod{1, T}, out::Tuple{}) where T = I2(T)

merge_pauli(::XGate{T}, ::YGate{T}) where T = ImZ(T)
merge_pauli(::XGate{T}, ::ZGate{T}) where T = -ImY(T)
merge_pauli(::YGate{T}, ::XGate{T}) where T = -ImZ(T)
merge_pauli(::YGate{T}, ::ZGate{T}) where T = ImX(T)
merge_pauli(::ZGate{T}, ::XGate{T}) where T = ImY(T)
merge_pauli(::ZGate{T}, ::YGate{T}) where T = ImX(T)

for G in [:X, :Y, :Z]
    GT = Symbol(G, :Gate)

    @eval merge_pauli(::I2Gate{T}, x::$GT{T}) where T = x
    @eval merge_pauli(x::$GT{T}, ::I2Gate{T}) where T = x
    @eval merge_pauli(::$GT{T}, ::$GT{T}) where T = I2(T)
end

merge_pauli(::I2Gate{T}, ::I2Gate{T}) where T = I2(T)
merge_pauli(x::PauliGroup, y::PauliGroup) = x * y

eliminate_nested(ex::AbstractBlock) = ex

# TODO: eliminate nested expr e.g chain(X, chain(X, Y))
function eliminate_nested(ex::Union{Prod, ChainBlock, Sum})
    _flatten(x) = (x, )
    _flatten(x::Union{Prod, ChainBlock}) = subblocks(x)

    isone(length(ex)) && return first(subblocks(ex))
    return chsubblocks(ex, Iterators.flatten(map(_flatten, subblocks(ex))))
end

# temporary utils
_unscale(x::AbstractBlock) = x
_unscale(x::Scale) = content(x)
_alpha(x::AbstractBlock{N, T}) where {N, T} = one(T)
_alpha(x::Scale) = x.alpha
_alpha(x::Scale{Val{S}}) where S = S

merge_scale(ex::AbstractBlock) = ex

function merge_scale(ex::Union{Scale{S, N, T}, Prod{N, T}, ChainBlock{N, T}}) where {S, N, T}
    alpha = one(T)

    for each in subblocks(ex)
        alpha *= _alpha(each)
    end

    ex = chsubblocks(ex, map(_unscale, subblocks(ex)))
    return alpha * ex
end

combine_similar(ex::AbstractBlock) = ex

function combine_similar(ex::Sum{N, T}) where {N, T}
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
            alpha = one(T)
            for (k, each) in enumerate(ex)
                if table[k] == true # checked term, skip
                    continue
                else
                    # check if unscaled term is the same
                    # merge them if they are
                    if _unscale(term) == _unscale(each)
                        alpha += _alpha(each)
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
        return Sum{N, T}(())
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
