using YaoArrayRegister
using YaoArrayRegister: matvec

export ControlBlock, control, cnot

struct ControlBlock{N, BT<:AbstractBlock, C, M} <: AbstractContainer{BT, N}
    ctrl_locs::NTuple{C, Int}
    ctrl_config::NTuple{C, Int}
    content::BT
    locs::NTuple{M, Int}
    function ControlBlock{N, BT, C, M}(ctrl_locs, ctrl_config, block, locs) where {N, C, M, BT<:AbstractBlock}
        @assert_locs_safe N (ctrl_locs..., locs...)
        @assert nqubits(block) == M "number of locations doesn't match the size of block"
        @assert block isa AbstractBlock "expect a block, got $(typeof(block))"
        new{N, BT, C, M}(ctrl_locs, ctrl_config, block, locs)
    end
end

"""
    decode_sign(ctrls...)

Decode signs into control sequence on control or inversed control.
"""
decode_sign(ctrls::Int...,) = decode_sign(ctrls)
decode_sign(ctrls::NTuple{N, Int}) where N = tuple(ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2))

function ControlBlock{N}(ctrl_locs::NTuple{C}, ctrl_config::NTuple{C}, block::BT, locs::NTuple{K}) where {N, M, C, K, BT<:AbstractBlock{M}}
    M == K || throw(DimensionMismatch("block position not maching its size!"))
    return ControlBlock{N, BT, C, M}(ctrl_locs, ctrl_config, block, locs)
end

function ControlBlock{N}(ctrl_locs::NTuple{C}, ctrl_config::NTuple{C}, block, locs::NTuple{K}) where {N, M, C, K}
    error("expect a block, got $(typeof(block))")
end

# control bit configs are 1 by default, it use sign to encode control bit code
ControlBlock{N}(ctrl_locs::NTuple{C}, block::AbstractBlock, locs::NTuple) where {N, C} =
    ControlBlock{N}(decode_sign(ctrl_locs)..., block, locs)
ControlBlock{N}(ctrl_locs::NTuple{C}, block::Function, locs::NTuple) where {N, C} =
    ControlBlock{N}(decode_sign(ctrl_locs)..., parse_block(length(locs), block), locs)
ControlBlock{N}(ctrl_locs::NTuple{C}, block, locs::NTuple) where {N, C} =
    ControlBlock{N}(decode_sign(ctrl_locs)..., block, locs) # trigger error

# use pair to represent block under control in a compact way
ControlBlock{N}(ctrl_locs::NTuple{C}, target::Pair) where {N, C} =
    ControlBlock{N}(ctrl_locs, target.second, (target.first...,))

"""
    control(n, ctrl_locs, target)

Return a [`ControlBlock`](@ref) with number of active qubits `n` and control locs
`ctrl_locs`, and control target in `Pair`.

# Example

```jldoctest
julia> control(4, (1, 2), 3=>X)
nqubits: 4
control(1, 2)
└─ (3,) X gate

julia> control(4, 1, 3=>X)
nqubits: 4
control(1)
└─ (3,) X gate
```
"""
control(total::Int, ctrl_locs, target::Pair) = ControlBlock{total}(Tuple(ctrl_locs), target)
control(total::Int, control_location::Int, target::Pair) = control(total, (control_location, ), target)

"""
    control(ctrl_locs, target) -> f(n)

Return a lambda that takes the number of total active qubits as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control((2, 3), 1=>X)
(n -> control(n, (2, 3), 1 => X gate))

julia> control(2, 1=>X)
(n -> control(n, 2, 1 => X gate))
```
"""
control(ctrl_locs, target::Pair) = @λ(n -> control(n, ctrl_locs, target))
control(control_location::Int, target::Pair) = @λ(n -> control(n, control_location, target))

"""
    control(target) -> f(ctrl_locs)

Return a lambda that takes a `Tuple` of control qubits locs as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control(1=>X)
(ctrl_locs -> control(ctrl_locs, 1 => X gate))

julia> control((2, 3) => YaoBlocks.ConstGate.CNOT)
(ctrl_locs -> control(ctrl_locs, (2, 3) => CNOT gate))
```
"""
control(target::Pair) = @λ(ctrl_locs -> control(ctrl_locs, target))

"""
    control(ctrl_locs::Int...) -> f(target)

Return a lambda that takes a `Pair` of control target as input.
See also [`control`](@ref).

# Example

```jldoctest
julia> control(1, 2)
(target -> control((1, 2), target))
```
"""
control(ctrl_locs::Int...) = @λ(target -> control(ctrl_locs, target))

"""
    cnot(n, ctrl_locs, location)

Return a speical [`ControlBlock`](@ref), aka CNOT gate with number of active qubits
`n` and locs of control qubits `ctrl_locs`, and `location` of `X` gate.

# Example

```jldoctest
julia> cnot(3, (2, 3), 1)
nqubits: 3
control(2, 3)
└─ (1,) X gate

julia> cnot(2, 1)
(n -> cnot(n, 2, 1))
```
"""
cnot(total::Int, ctrl_locs, locs::Int) = control(total, ctrl_locs, locs=>X)
cnot(ctrl_locs, loc::Int) = @λ(n -> cnot(n, ctrl_locs, loc))

mat(::Type{T}, c::ControlBlock{N, BT, C}) where {T, N, BT, C} = cunmat(N, c.ctrl_locs, c.ctrl_config, mat(T, c.content), c.locs)

function apply!(r::ArrayReg{B, T}, c::ControlBlock) where {B, T}
    _check_size(r, c)
    instruct!(matvec(r.state), mat(T, c.content), c.locs, c.ctrl_locs, c.ctrl_config)
    return r
end

# specialization
for G in [:X, :Y, :Z, :S, :T, :Sdag, :Tdag]
    GT = Expr(:(.), :ConstGate, QuoteNode(Symbol(G, :Gate)))

    @eval function apply!(r::ArrayReg, c::ControlBlock{N, <:$GT}) where N
        _check_size(r, c)
        instruct!(matvec(r.state), Val($(QuoteNode(G))), c.locs, c.ctrl_locs, c.ctrl_config)
        return r
    end
end

PreserveStyle(::ControlBlock) = PreserveAll()

occupied_locs(c::ControlBlock) = (c.ctrl_locs..., map(x->c.locs[x], occupied_locs(c.content))...)
chsubblocks(pb::ControlBlock{N}, blk::AbstractBlock) where {N} = ControlBlock{N}(pb.ctrl_locs, pb.ctrl_config, blk, pb.locs)

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.content)

function Base.:(==)(lhs::ControlBlock{N, BT, C, M}, rhs::ControlBlock{N, BT, C, M}) where {BT, N, C, M}
    return (lhs.ctrl_locs == rhs.ctrl_locs) && (lhs.content == rhs.content) && (lhs.locs == rhs.locs)
end

Base.adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_locs, blk.ctrl_config, adjoint(blk.content), blk.locs)

# NOTE: we only copy one hierachy (shallow copy) for each block
function Base.copy(ctrl::ControlBlock{N, BT, C, M}) where {BT, N, C, M}
    return ControlBlock{N, BT, C, M}(ctrl.ctrl_locs, ctrl.ctrl_config, ctrl.content, ctrl.locs)
end

function YaoBase.iscommute(x::ControlBlock{N}, y::ControlBlock{N}) where N
    if x.locs == y.locs && x.ctrl_locs == y.ctrl_locs
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
