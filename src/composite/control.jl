using YaoArrayRegister
using YaoArrayRegister: matvec

export ControlBlock, control

struct ControlBlock{N, BT<:AbstractBlock, C, M, T} <: AbstractContainer{N, T, BT}
    ctrl_locations::NTuple{C, Int}
    ctrl_config::NTuple{C, Int}
    content::BT
    locations::NTuple{M, Int}
    function ControlBlock{N, BT, C, M, T}(ctrl_locations, ctrl_config, block, locations) where {N, C, M, T, BT<:AbstractBlock}
        @assert_locs N (ctrl_locations..., locations...)
        new{N, BT, C, M, T}(ctrl_locations, ctrl_config, block, locations)
    end
end

"""
    decode_sign(ctrls...)

Decode signs into control sequence on control or inversed control.
"""
decode_sign(ctrls::Int...,) = decode_sign(ctrls)
decode_sign(ctrls::NTuple{N, Int}) where N = tuple(ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2))

function ControlBlock{N}(ctrl_locations::NTuple{C}, ctrl_config::NTuple{C}, block::BT, locations::NTuple{K}) where {N, M, C, K, T, BT<:AbstractBlock{M, T}}
    M == K || throw(DimensionMismatch("block position not maching its size!"))
    return ControlBlock{N, BT, C, M, T}(ctrl_locations, ctrl_config, block, locations)
end

# control bit configs are 1 by default, it use sign to encode control bit code
ControlBlock{N}(ctrl_locations::NTuple{C}, block::AbstractBlock, locations::NTuple) where {N, C} =
    ControlBlock{N}(decode_sign(ctrl_locations)..., block, locations)

# use pair to represent block under control in a compact way
ControlBlock{N}(ctrl_locations::NTuple{C}, target::Pair) where {N, C} =
    ControlBlock{N}(ctrl_locations, target.second, (target.first...,))

"""
    control(n, ctrl_locations, target)

Return a [`ControlBlock`](@ref) with number of active qubits `n` and control locations
`ctrl_locations`, and control target in `Pair`.

# Example

```jldoctest
julia> control(4, (1, 2), 3=>X)
julia> control(4, 1, 3=>X)
```
"""
control(total::Int, ctrl_locations, target::Pair) = ControlBlock{total}(Tuple(ctrl_locations), target)
control(total::Int, control_location::Int, target::Pair) = control(total, (control_location, ), target)

"""
    control(ctrl_locations, target) -> f(n)

Return a lambda that takes the number of total active qubits as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control((2, 3), 1=>X)
julia> control(2, 1=>X)
```
"""
control(ctrl_locations, target::Pair) = @λ(n -> control(n, ctrl_locations, target))
control(control_location::Int, target::Pair) = @λ(n -> control(n, control_location, target))

"""
    control(target) -> f(ctrl_locations)

Return a lambda that takes a `Tuple` of control qubits locations as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control(1=>X)
julia> control((2, 3) => CNOT)
```
"""
control(target::Pair) = @λ(ctrl_locations -> control(ctrl_locations, target))

"""
    control(ctrl_locations::Int...) -> f(target)

Return a lambda that takes a `Pair` of control target as input.
See also [`control`](@ref).

# Example

```jldoctest
julia> control(1, 2)
```
"""
control(ctrl_locations::Int...) = @λ(target -> control(ctrl_locations, target))

"""
    cnot(n, ctrl_locations, location)

Return a speical [`ControlBlock`](@ref), aka CNOT gate with number of active qubits
`n` and locations of control qubits `ctrl_locations`, and `location` of `X` gate.

# Example

```jldoctest
julia> cnot(3, 2, 1)
julia> cnot(2, 1)
```
"""
cnot(total::Int, ctrl_locations, location::Int) = control(total, control_location, locations=>X)
cnot(ctrl_locations, location::Int) = @λ(n -> cnot(n, ctrl_locations, location))

mat(c::ControlBlock{N, BT, C}) where {N, BT, C} = cunmat(N, c.ctrl_locations, c.ctrl_config, mat(c.content), c.locations)

function apply!(r::ArrayReg, c::ControlBlock)
    instruct!(matvec(r.state), mat(c.content), c.locations, c.ctrl_locations, c.ctrl_config)
    return r
end

PreserveStyle(::ControlBlock) = PreserveAll()

occupied_locs(c::ControlBlock) = (c.ctrl_locations..., map(x->c.locations[x], occupied_locs(c.content))...)
chsubblocks(pb::ControlBlock{N}, blk::AbstractBlock) where {N} = ControlBlock{N}(pb.ctrl_locations, pb.ctrl_config, blk, pb.locations)

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.content)

function Base.:(==)(lhs::ControlBlock{N, BT, C, M, T}, rhs::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return (lhs.ctrl_locations == rhs.ctrl_locations) && (lhs.content == rhs.content) && (lhs.locations == rhs.locations)
end

Base.adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_locations, blk.ctrl_config, adjoint(blk.content), blk.locations)

# NOTE: we only copy one hierachy (shallow copy) for each block
function Base.copy(ctrl::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return ControlBlock{N, BT, C, M, T}(ctrl.ctrl_locations, ctrl.ctrl_config, ctrl.content, ctrl.locations)
end

function YaoBase.iscommute(x::ControlBlock{N}, y::ControlBlock{N}) where N
    if x.locations == y.locations && x.ctrl_locations == y.ctrl_locations
        return iscommute(x.content, y.content)
    else
        return iscommute_fallback(x, y)
    end
end
