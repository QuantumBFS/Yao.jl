import StaticArrays: SizedVector
export PauliString

# TODO: expand to Clifford?
struct PauliString{N, T, BT <: ConstantGate{1, T}, VT <: SizedVector{N, BT}} <: CompositeBlock{N, T}
    blocks::VT
    PauliString(blocks::SizedVector{N, BT}) where {N, T, BT <: ConstantGate{1, T}} =
        new{N, T, BT, typeof(blocks)}(blocks)
end

# NOTE: PauliString has a fixed size `N`, thus by default, it should use
#      SizedVector, or this block could be actually not correct.

"""
    PauliString(xs::PauliGate...)

Create a `PauliString` from some Pauli gates.

# Example

```jldoctest
julia> PauliString(X, Y, Z)
nqubits: 3, datatype: Complex{Float64}
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
PauliString(xs::PauliGate{T}...) where T = PauliString(SizedVector{length(xs), PauliGate{T}}(xs))

"""
    PauliString(list::Vector)

Create a `PauliString` from a list of Pauli gates.

# Example

```jldoctest
julia> PauliString([X, Y, Z])
nqubits: 3, datatype: Complex{Float64}
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
function PauliString(xs::Vector)
    T = datatype(first(xs))
    for each in xs
        if !(each isa PauliGate)
            error("expect pauli gates")
        end

        datatype(each) == T || error("expect data type to be $T")
    end
    return PauliString(SizedVector{length(xs), PauliGate{T}}(xs))
end

subblocks(ps::PauliString) = ps.blocks
chsubblocks(pb::PauliString, blocks::Vector) = PauliString(blocks)
chsubblocks(pb::PauliString, it) = PauliString(collect(it))

occupied_locs(ps::PauliString) = findall(x->!(x isa I2Gate), ps.blocks)

cache_key(ps::PauliString) = map(cache_key, ps.blocks)

YaoBase.ishermitian(::PauliString) = true
YaoBase.isreflexive(::PauliString) = true
YaoBase.isunitary(::PauliString) = true

Base.copy(ps::PauliString) = PauliString(copy(ps.blocks))
Base.getindex(ps::PauliString, x) = getindex(ps.blocks, x)
Base.lastindex(ps::PauliString) = lastindex(ps.blocks)
Base.iterate(ps::PauliString) = iterate(ps.blocks)
Base.iterate(ps::PauliString, st) = iterate(ps.blocks, st)
Base.length(ps::PauliString) = length(ps.blocks)
Base.eltype(ps::PauliString) = eltype(ps.blocks)
Base.eachindex(ps::PauliString) = eachindex(ps.blocks)
Base.getindex(ps::PauliString, index::Union{UnitRange, Vector}) =
    PauliString(getindex(ps.blocks, index))
function Base.setindex!(ps::PauliString, v::PauliGate, index::Union{Int})
    ps.blocks[index] = v
    return ps
end

function Base.:(==)(lhs::PauliString{N, T}, rhs::PauliString{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

xgates(ps::PauliString{N}) where N = RepeatedBlock{N}(X, (findall(x->x isa XGate, (ps.blocks...,))...,))
ygates(ps::PauliString{N}) where N = RepeatedBlock{N}(Y, (findall(x->x isa YGate, (ps.blocks...,))...,))
zgates(ps::PauliString{N}) where N = RepeatedBlock{N}(Z, (findall(x->x isa ZGate, (ps.blocks...,))...,))

function apply!(reg::ArrayReg, ps::PauliString)
    _check_size(reg, ps)
    for pauligates in [xgates, ygates, zgates]
        blk = pauligates(ps)
        apply!(reg, blk)
    end
    return reg
end

function mat(ps::PauliString)
    return mat(xgates(ps)) * mat(ygates(ps)) * mat(zgates(ps))
end
