export ControlBlock, control, cnot, cz

struct ControlBlock{BT<:AbstractBlock,C,M} <: AbstractContainer{BT,2}
    n::Int
    ctrl_locs::NTuple{C,Int}
    ctrl_config::NTuple{C,Int}
    content::BT
    locs::NTuple{M,Int}
    function ControlBlock{BT,C,M}(n,
        ctrl_locs,
        ctrl_config,
        block,
        locs,
    ) where {C,M,BT<:AbstractBlock}
        @assert_locs_safe n (ctrl_locs..., locs...)
        @assert nqudits(block) == M "number of locations doesn't match the size of block"
        @assert block isa AbstractBlock "expect a block, got $(typeof(block))"
        new{BT,C,M}(n, ctrl_locs, ctrl_config, block, locs)
    end
end

"""
    decode_sign(ctrls...)

Decode signs into control sequence on control or inversed control.
"""
decode_sign(ctrls::NTuple{N,Int}) where {N} =
    tuple(ctrls .|> abs, ctrls .|> sign .|> (x -> (1 + x) ÷ 2))

function ControlBlock(n::Int,
    ctrl_locs::NTuple{C},
    ctrl_config::NTuple{C},
    block::BT,
    locs::NTuple{K},
) where {C,K,BT<:AbstractBlock{2}}
    nqudits(block) == K || throw(DimensionMismatch("block position not maching its size!"))
    return ControlBlock{BT,C,K}(n, ctrl_locs, ctrl_config, block, locs)
end

# control bit configs are 1 by default, it use sign to encode control bit code
ControlBlock(n::Int, ctrl_locs::NTuple{C}, block::AbstractBlock, locs::NTuple) where {C} =
    ControlBlock(n::Int, decode_sign(ctrl_locs)..., block, locs)

# use pair to represent block under control in a compact way
ControlBlock(n::Int, ctrl_locs::NTuple{C}, target::Pair) where {C} =
    ControlBlock(n, ctrl_locs, target.second, (target.first...,))

nqudits(c::ControlBlock) = c.n

"""
    control(n, ctrl_locs, target)

Return a [`ControlBlock`](@ref) with number of active qubits `n` and control locs
`ctrl_locs`, and control target in `Pair`.

# Example

```jldoctest; setup=:(using Yao)
julia> control(4, (1, 2), 3=>X)
nqubits: 4
control(1, 2)
└─ (3,) X

julia> control(4, 1, 3=>X)
nqubits: 4
control(1)
└─ (3,) X
```
"""
control(total::Int, ctrl_locs, target::Pair) = ControlBlock(total, Tuple(ctrl_locs), target)
control(total::Int, control_location::Int, target::Pair) =
    control(total, (control_location,), target)

"""
    control(ctrl_locs, target) -> f(n)

Return a lambda that takes the number of total active qubits as input. See also
[`control`](@ref).

### Examples

```jldoctest; setup=:(using YaoBlocks)
julia> control((2, 3), 1=>X)
(n -> control(n, (2, 3), 1 => X))

julia> control(2, 1=>X)
(n -> control(n, 2, 1 => X))
```
"""
control(ctrl_locs, target::Pair) = @λ(n -> control(n, ctrl_locs, target))
control(control_location::Int, target::Pair) = @λ(n -> control(n, control_location, target))

"""
    cnot([n, ]ctrl_locs, location)

Return a speical [`ControlBlock`](@ref), aka CNOT gate with number of active qubits
`n` and locs of control qubits `ctrl_locs`, and `location` of `X` gate.

### Examples

```jldoctest; setup=:(using YaoBlocks)
julia> cnot(3, (2, 3), 1)
nqubits: 3
control(2, 3)
└─ (1,) X

julia> cnot(2, 1)
(n -> cnot(n, 2, 1))
```
"""
cnot(total::Int, ctrl_locs, locs::Int) = control(total, ctrl_locs, locs => X)
cnot(ctrl_locs, loc::Int) = @λ(n -> cnot(n, ctrl_locs, loc))

"""
    cz([n, ]ctrl_locs, location)

Return a speical [`ControlBlock`](@ref), aka CZ gate with number of active qubits
`n` and locs of control qubits `ctrl_locs`, and `location` of `Z` gate. See also
[`cnot`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> cz(2, 1, 2)
nqubits: 2
control(1)
└─ (2,) Z
```
"""
cz(total::Int, ctrl_locs, locs::Int) = control(total, ctrl_locs, locs => Z)
cz(ctrl_locs, loc::Int) = @λ(n -> cz(n, ctrl_locs, loc))


mat(::Type{T}, c::ControlBlock{BT,C}) where {T,BT,C} =
    cunmat(c.n, c.ctrl_locs, c.ctrl_config, mat(T, c.content), c.locs)

function _apply!(r::AbstractRegister, c::ControlBlock)
    instruct!(r, mat_matchreg(r, c.content), c.locs, c.ctrl_locs, c.ctrl_config)
    return r
end

# specialization
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))

    @eval function _apply!(r::AbstractRegister, c::ControlBlock{<:$GT})
        instruct!(r, Val($(QuoteNode(G))), c.locs, c.ctrl_locs, c.ctrl_config)
        return r
    end
end

PropertyTrait(::ControlBlock) = PreserveAll()

occupied_locs(c::ControlBlock) =
    (c.ctrl_locs..., map(x -> c.locs[x], occupied_locs(c.content))...)
chsubblocks(pb::ControlBlock, blk::AbstractBlock) =
    ControlBlock(pb.n, pb.ctrl_locs, pb.ctrl_config, blk, pb.locs)

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.content)

function Base.:(==)(
    lhs::ControlBlock{BT,C,M},
    rhs::ControlBlock{BT,C,M},
) where {BT,C,M}
    return nqudits(lhs) == nqudits(rhs) &&
            (lhs.ctrl_locs == rhs.ctrl_locs) &&
           (lhs.content == rhs.content) &&
           (lhs.locs == rhs.locs)
end

Base.adjoint(blk::ControlBlock) =
    ControlBlock(blk.n, blk.ctrl_locs, blk.ctrl_config, adjoint(blk.content), blk.locs)

# NOTE: we only copy one hierachy (shallow copy) for each block
function Base.copy(ctrl::ControlBlock{BT,C,M}) where {BT,C,M}
    return ControlBlock{BT,C,M}(ctrl.n, ctrl.ctrl_locs, ctrl.ctrl_config, ctrl.content, ctrl.locs)
end

function YaoAPI.iscommute(x::ControlBlock, y::ControlBlock)
    _check_block_sizes(x, y)
    if x.locs == y.locs
        return iscommute(x.content, y.content)
    elseif !any(l -> l in y.ctrl_locs, x.locs) && !any(l -> l in x.ctrl_locs, y.locs)
        return true
    else
        return iscommute_fallback(x, y)
    end
end

function unsafe_getindex(::Type{T}, ctrl::ControlBlock, i::Integer, j::Integer) where {T,D}
    getindex2(T, Val{2}(), nqudits(ctrl), ctrl.content, ctrl.locs, ctrl.ctrl_locs, ctrl.ctrl_config, i, j)
end
function unsafe_getcol(::Type{T}, ctrl::ControlBlock, j::DitStr{D}) where {T,D}
    getindexr(T, ctrl.content, ctrl.locs, ctrl.ctrl_locs, ctrl.ctrl_config, j)
end