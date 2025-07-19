"""
circuit optimisation
"""
module Optimise
using YaoBlocks, YaoBlocks.ConstGate
using YaoBlocks: NotImplementedError

export replace_block, flatten_basic, simplify, raise_chain, canonicalize, to_basictypes, is_pauli
export merge_pauli, eliminate_nested, merge_scale, combine_similar

"""
    replace_block(actor, tree::AbstractBlock) -> AbstractBlock
    replace_block(pair::Pair{Type{ST}, TT}, tree::AbstractBlock) -> AbstractBlock

replace blocks in a circuit, where `actor` is a function that given input block,
returns the block to replace, or `nothing` for skip replacing and visit sibling.
If `pair` is provided, then replace original block with type `ST` with new block (`pair.second`).
"""
function replace_block(actor, tree::AbstractBlock)
    res = actor(tree)
    if res === tree || res === nothing # not replaced
        return chsubblocks(tree, replace_block.(Ref(actor), subblocks(tree)))
    else
        return res
    end
end

function replace_block(
    pair::Pair{ST,TT},
    tree::AbstractBlock,
) where {ST<:AbstractBlock,TT<:AbstractBlock}
    replace_block(x -> (x == pair.first ? pair.second : nothing), tree)
end


"""
    to_basictypes(block::AbstractBlock)

convert gates to basic types

    * ChainBlock
    * PutBlock
    * PrimitiveBlock
"""
function to_basictypes end

to_basictypes(block::PrimitiveBlock) = block
to_basictypes(block::MixedUnitaryChannel) = block
to_basictypes(block::KrausChannel) = block
to_basictypes(block::DepolarizingChannel) = block
to_basictypes(block::SuperOp) = block
function to_basictypes(block::AbstractBlock)
    throw(NotImplementedError(:to_basictypes, typeof(block)))
end

function to_basictypes(block::RepeatedBlock)
    chain(block.n, map(i -> put(block.n, i => content(block)), block.locs))
end

to_basictypes(block::CachedBlock) = content(block)
function to_basictypes(block::Subroutine{D,<:PrimitiveBlock}) where {D}
    put(nqudits(block), block.locs => content(block))
end
function to_basictypes(block::Subroutine)
    to_basictypes(map_address(content(block), AddressInfo(block.n, [block.locs...])))
end
function to_basictypes(block::Subroutine{D,<:Measure}) where {D}
    map_address(content(block), AddressInfo(nqudits(block), [block.locs...]))
end
to_basictypes(block::Daggered) = Daggered(block.content)
to_basictypes(block::Scale) = Scale(block.alpha, block.content)
to_basictypes(block::KronBlock) =
    chain(block.n, [put(block.n, i => block[i]) for i in block.locs])
to_basictypes(block::Union{Add,PutBlock,ChainBlock,ControlBlock}) = block

"""
    is_pauli(x)

Check if `x` is an element of pauli group.
"""
is_pauli(xs...) = all(is_pauli, xs)
is_pauli(::Union{XGate,YGate, ZGate, I2Gate}) = true
is_pauli(::AbstractBlock) = false
function is_pauli(s::Scale)
    if factor(s) == im || factor(s) == -im || factor(s) == 1 || factor(s) == -1
        return is_pauli(content(s))
    else
        return false
    end
end

for G in [:I2, :X, :Y, :Z]
    ImG = Symbol(:Im, G)
    nImG = Symbol(:nIm, G)
    nG = Symbol(:n, G)

    @eval const $ImG = im * $G
    @eval const $nImG = -im * $G
    @eval const $nG = -$G
end

merge_pauli(x) = x
merge_pauli(x::AbstractBlock, y::AbstractBlock) = x * y

function merge_pauli(ex::ChainBlock)
    if ex.n != 1
        return ex
    end
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

eliminate_nested(ex::AbstractBlock) = ex

# eliminate nested put blocks
function eliminate_nested(ex::PutBlock)
    content = eliminate_nested(ex.content)
    if content isa PutBlock
        return put(nqubits(ex), map(x -> ex.locs[x], content.locs) => content.content)
    else
        return ex
    end
end

function eliminate_nested(ex::T) where {T<:Union{ChainBlock,Add}}
    _flatten(x) = (x,)
    _flatten(x::T) = subblocks(x)

    isone(length(ex)) && return first(subblocks(ex))
    return chsubblocks(ex, collect(AbstractBlock{nlevel(ex)}, Iterators.flatten(map(_flatten, subblocks(ex)))))
end

raise_chain(ex::AbstractBlock) = ex
raise_chain(ex::ChainBlock) = chain([raise_chain(block) for block in ex])
function raise_chain(ex::PutBlock)
    content = raise_chain(ex.content)
    if content isa ChainBlock
        return chain([put(nqubits(ex), ex.locs => block) for block in content])
    else
        return ex
    end
end

# temporary utils
_unscale(x::AbstractBlock) = x
_unscale(x::Scale) = content(x)
merge_alpha(alpha, x::AbstractBlock) = alpha
merge_alpha(alpha, x::Scale) = alpha * x.alpha
merge_alpha(alpha, x::Scale{Val{S}}) where {S} = alpha * S

# since we don't have T in blocks, this is a workaround
# to get correct identity in type stable term
merge_alpha(::Nothing, x::Scale) = x.alpha
merge_alpha(::Nothing, x::Scale{Val{S}}) where {S} = S
merge_alpha(::Nothing, x::AbstractBlock) = nothing

merge_scale(ex::AbstractBlock) = ex

# a simple function to find one for Val and Number
_one(x) = one(x)
_one(::Type{Val{S}}) where {S} = one(S)
_one(::Val{S}) where {S} = one(S)



function merge_scale(ex::Union{Scale{S,N},ChainBlock{N}}) where {S,N}
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

combine_similar(ex::AbstractBlock) = ex

combine_alpha(alpha, x) = alpha
combine_alpha(alpha, x::AbstractBlock) = alpha + 1
combine_alpha(alpha, x::Scale) = alpha + x.alpha
combine_alpha(alpha, x::Scale{Val{S}}) where {S} = alpha + S

function combine_similar(ex::Add{D}) where D
    table = zeros(Bool, length(ex))
    list = AbstractBlock{D}[]
    p = 1
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
        return Add(ex.n)
    else
        return Add(ex.n, list)
    end
end

const __default_simplification_rules__ =
    Function[merge_pauli, eliminate_nested, merge_scale, combine_similar]
const __flatten_basic__ = Function[eliminate_nested, to_basictypes]
const __canonicalize__ = Function[eliminate_nested, raise_chain, to_basictypes]

flatten_basic(ex::AbstractBlock) = simplify(ex; rules = __flatten_basic__)
canonicalize(ex::AbstractBlock) = simplify(ex; rules = __canonicalize__)

# Inspired by MasonPotter/Symbolics.jl
"""
    simplify(block[; rules=__default_simplification_rules__])

Simplify a block tree accroding to given rules, default to use
`YaoBlocks.Optimise.__default_simplification_rules__`.
"""
function simplify(ex::AbstractBlock; rules = __default_simplification_rules__)
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
    if length(subblocks(ex)) > 0
        ex = chsubblocks(ex, map(x -> simplify_pass(rules, x), subblocks(ex)))
    end

    for rule in rules
        ex = rule(ex)
    end
    return ex
end

end
