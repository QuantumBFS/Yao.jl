using YaoArrayRegister
using YaoArrayRegister: matvec

export ControlBlock, control

struct ControlBlock{N, BT<:AbstractBlock, C, M, T} <: AbstractContainer{N, T, BT}
    ctrl_qubits::NTuple{C, Int}
    vals::NTuple{C, Int}
    block::BT
    addrs::NTuple{M, Int}
    function ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs) where {N, C, M, T, BT<:AbstractBlock}
        @assert_addrs N (ctrl_qubits..., addrs...)
        new{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
    end
end

"""
    decode_sign(ctrls...)

Decode signs into control sequence on control or inversed control.
"""
decode_sign(ctrls::Int...,) = decode_sign(ctrls)
decode_sign(ctrls::NTuple{N, Int}) where N = tuple(ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2))

function ControlBlock{N}(ctrl_qubits::NTuple{C}, vals::NTuple{C}, block::BT, addrs::NTuple{K}) where {N, M, C, K, T, BT<:AbstractBlock{M, T}}
    M == K || throw(DimensionMismatch("block position not maching its size!"))
    return ControlBlock{N, BT, C, M, T}(ctrl_qubits, vals, block, addrs)
end

# control bit configs are 1 by default, it use sign to encode control bit code
ControlBlock{N}(ctrl_qubits::NTuple{C}, block::AbstractBlock, addrs::NTuple) where {N, C} =
    ControlBlock{N}(decode_sign(ctrl_qubits)..., block, addrs)

# use pair to represent block under control in a compact way
ControlBlock{N}(ctrl_qubits::NTuple{C}, target::Pair) where {N, C} =
    ControlBlock{N}(ctrl_qubits, target.second, (target.first...,))

"""
    control(n, control_locations, target)

Return a [`ControlBlock`](@ref) with number of active qubits `n` and control locations
`control_locations`, and control target in `Pair`.

# Example

```jldoctest
julia> control(4, (1, 2), 3=>X)
julia> control(4, 1, 3=>X)
```
"""
control(total::Int, control_locations, target::Pair) = ControlBlock{total}(Tuple(control_locations), target)
control(total::Int, control_location::Int, target::Pair) = control(total, (control_location, ), target)

"""
    control(control_locations, target) -> f(n)

Return a lambda that takes the number of total active qubits as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control((2, 3), 1=>X)
julia> control(2, 1=>X)
```
"""
control(control_locations, target::Pair) = @λ(n -> control(n, control_locations, target))
control(control_location::Int, target::Pair) = @λ(n -> control(n, control_location, target))

"""
    control(target) -> f(control_locations)

Return a lambda that takes a `Tuple` of control qubits locations as input. See also
[`control`](@ref).

# Example

```jldoctest
julia> control(1=>X)
julia> control((2, 3) => CNOT)
```
"""
control(target::Pair) = @λ(control_locations -> control(control_locations, target))

"""
    control(control_locations::Int...) -> f(target)

Return a lambda that takes a `Pair` of control target as input.
See also [`control`](@ref).

# Example

```jldoctest
julia> control(1, 2)
```
"""
control(control_locations::Int...) = @λ(target -> control(control_locations, target))

"""
    cnot(n, control_locations, location)

Return a speical [`ControlBlock`](@ref), aka CNOT gate with number of active qubits
`n` and locations of control qubits `control_locations`, and `location` of `X` gate.

# Example

```jldoctest
julia> cnot(3, 2, 1)
julia> cnot(2, 1)
```
"""
cnot(total::Int, control_locations, location::Int) = control(total, control_location, locations=>X)
cnot(control_locations, location::Int) = @λ(n -> cnot(n, control_locations, location))

mat(c::ControlBlock{N, BT, C}) where {N, BT, C} = cunmat(N, c.ctrl_qubits, c.vals, mat(c.block), c.addrs)

function apply!(r::ArrayReg, c::ControlBlock)
    instruct!(matvec(r.state), mat(c.block), c.addrs, c.ctrl_qubits, c.vals)
    return r
end

PreserveStyle(::ControlBlock) = PreserveAll()

occupied_locations(c::ControlBlock) = (c.ctrl_qubits..., map(x->c.addrs[x], occupied_locations(c.block))...)
chsubblocks(pb::ControlBlock{N}, blk::AbstractBlock) where {N} = ControlBlock{N}(pb.ctrl_qubits, pb.vals, blk, pb.addrs)

# NOTE: ControlBlock will forward parameters directly without loop
cache_key(ctrl::ControlBlock) = cache_key(ctrl.block)

function Base.:(==)(lhs::ControlBlock{N, BT, C, M, T}, rhs::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return (lhs.ctrl_qubits == rhs.ctrl_qubits) && (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

Base.adjoint(blk::ControlBlock{N}) where N = ControlBlock{N}(blk.ctrl_qubits, blk.vals, adjoint(blk.block), blk.addrs)

# NOTE: we only copy one hierachy (shallow copy) for each block
function Base.copy(ctrl::ControlBlock{N, BT, C, M, T}) where {BT, N, C, M, T}
    return ControlBlock{N, BT, C, M, T}(ctrl.ctrl_qubits, ctrl.vals, ctrl.block, ctrl.addrs)
end

function YaoBase.iscommute(x::ControlBlock{N}, y::ControlBlock{N}) where N
    if x.addrs == y.addrs && x.ctrl_qubits == y.ctrl_qubits
        return iscommute(x.block, y.block)
    else
        return iscommute_fallback(x, y)
    end
end
