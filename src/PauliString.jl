export PauliString

struct PauliString{N, T, VT<:AbstractVector{PauliGate{T}}} <: CompositeBlock{N, T}
    blocks::VT
    PauliString(blocks::AbstractVector{PauliGate{T}}) where T = new{length(blocks), T, typeof(blocks)}(blocks)
end

YaoBase.ishermitian(::PauliString) = true
YaoBase.isreflexive(::PauliString) = true
YaoBase.isunitary(::PauliString) = true
Base.copy(ps::PauliString) = PauliString(copy(ps.blocks))

subblocks(ps::PauliString) = ps.blocks
addrs(ps::PauliString{N}) where N = collect(1:N)
usedbits(ps::PauliString) = findall(x->!(x isa I2Gate), ps.blocks)
chsubblocks(pb::PauliString, blocks) = PauliString(blocks)

@forward PauliString.blocks Base.getindex, Base.lastindex, Base.setindex!, Base.iterate, Base.length, Base.eltype, Base.eachindex
Base.getindex(ps::PauliString, index::Union{UnitRange, Vector}) = PauliString(getindex(ps.blocks, index))

function cache_key(ps::PauliString)
    [cache_key(each) for each in ps.blocks]
end

function Base.hash(ps::PauliString, h::UInt)
    hashkey = hash(objectid(ps), h)
    for each in ps.blocks
        hashkey = hash(each, hashkey)
    end
    hashkey
end

function Base.:(==)(lhs::PauliString{N, T}, rhs::PauliString{N, T}) where {N, T}
    (length(lhs.blocks) == length(rhs.blocks)) && all(lhs.blocks .== rhs.blocks)
end

function print_block(io::IO, x::PauliString)
    printstyled(io, "PauliString"; bold=true, color=color(PauliString))
end

xgates(ps::PauliString{N}) where N = RepeatedBlock{N}(X, (findall(x->x isa XGate, (ps.blocks...,))...,))
ygates(ps::PauliString{N}) where N = RepeatedBlock{N}(Y, (findall(x->x isa YGate, (ps.blocks...,))...,))
zgates(ps::PauliString{N}) where N = RepeatedBlock{N}(Z, (findall(x->x isa ZGate, (ps.blocks...,))...,))

function apply!(reg::DenseRegister, ps::PauliString)
    for pauligates in [xgates, ygates, zgates]
        blk = pauligates(ps)
        apply!(reg, blk)
    end
    reg
end

function mat(ps::PauliString)
    mat(xgates(ps)) * mat(ygates(ps)) * mat(zgates(ps))
end
