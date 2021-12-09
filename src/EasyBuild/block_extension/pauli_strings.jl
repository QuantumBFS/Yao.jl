import YaoBlocks.YaoArrayRegister.StaticArrays: SizedVector
import YaoBlocks.YaoArrayRegister.StatsBase
using YaoBlocks: PauliGate
export PauliString

# TODO: expand to Clifford?
struct PauliString{N, BT <: ConstantGate{1}, VT <: SizedVector{N, BT}} <: CompositeBlock{N}
    blocks::VT
    PauliString(blocks::SizedVector{N, BT}) where {N, BT <: ConstantGate{1}} =
        new{N, BT, typeof(blocks)}(blocks)
end

"""
    PauliString(xs::PauliGate...)

Create a `PauliString` from some Pauli gates.

# Example

```julia
julia> PauliString(X, Y, Z)
nqubits: 3
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
PauliString(xs::PauliGate...) = PauliString(SizedVector{length(xs), PauliGate}(xs))

"""
    PauliString(list::Vector)

Create a `PauliString` from a list of Pauli gates.

# Example

```julia
julia> PauliString([X, Y, Z])
nqubits: 3
PauliString
├─ X gate
├─ Y gate
└─ Z gate
```
"""
function PauliString(xs::Vector)
    for each in xs
        if !(each isa PauliGate)
            error("expect pauli gates")
        end
    end
    return PauliString(SizedVector{length(xs), PauliGate}(xs))
end

YaoAPI.subblocks(ps::PauliString) = ps.blocks
YaoAPI.chsubblocks(pb::PauliString, blocks::Vector) = PauliString(blocks)
YaoAPI.chsubblocks(pb::PauliString, it) = PauliString(collect(it))

YaoAPI.occupied_locs(ps::PauliString) = (findall(x->!(x isa I2Gate), ps.blocks)...,)

YaoBlocks.cache_key(ps::PauliString) = map(cache_key, ps.blocks)

LinearAlgebra.ishermitian(::PauliString) = true
YaoAPI.isreflexive(::PauliString) = true
YaoAPI.isunitary(::PauliString) = true

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

function Base.:(==)(lhs::PauliString{N}, rhs::PauliString{N}) where N
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

xgates(ps::PauliString{N}) where N = RepeatedBlock{N}(X, (findall(x->x isa XGate, (ps.blocks...,))...,))
ygates(ps::PauliString{N}) where N = RepeatedBlock{N}(Y, (findall(x->x isa YGate, (ps.blocks...,))...,))
zgates(ps::PauliString{N}) where N = RepeatedBlock{N}(Z, (findall(x->x isa ZGate, (ps.blocks...,))...,))

function _apply!(reg::AbstractRegister, ps::PauliString)
    for pauligates in [xgates, ygates, zgates]
        blk = pauligates(ps)
        _apply!(reg, blk)
    end
    return reg
end

function YaoAPI.mat(::Type{T}, ps::PauliString) where T
    return mat(T, xgates(ps)) * mat(T, ygates(ps)) * mat(T, zgates(ps))
end

function YaoBlocks.print_block(io::IO, x::PauliString)
    printstyled(io, "PauliString"; bold=true, color=YaoBlocks.color(PauliString))
end

YaoBlocks.color(::Type{T}) where {T <: PauliString} = :cyan
