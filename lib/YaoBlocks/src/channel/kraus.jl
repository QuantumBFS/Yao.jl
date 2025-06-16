"""
    KrausChannel{D} <: AbstractQuantumChannel{D}
    KrausChannel(operators)

Create a Kraus representation of a quantum channel, where `operators` is a list of Kraus operators.
The kraus channel is defined as below

```math
\\phi(\\rho) = \\sum_i K_i ρ K_i^\\dagger,
```

where ``\\rho`` in a [`DensityMatrix`](@ref) as the register to apply on, ``K_i`` is the i-th operator in `operators`.

### Examples

```jldoctest; setup=:(using Yao)
julia> KrausChannel([X, Y, Z])
nqubits: 1
kraus_channel
├─ X
├─ Y
└─ Z
```
"""
struct KrausChannel{D} <: AbstractQuantumChannel{D}
    n::Int
    operators::Vector{AbstractBlock{D}}
    function KrausChannel(operators::Vector{AbstractBlock{D}}) where D
        n = _check_block_sizes(operators)
        new{D}(n, operators)
    end
end
function KrausChannel(it)
    length(it) == 0 && error("The input operator list size can not be 0!")
    D = nlevel(first(it))
    KrausChannel(collect(AbstractBlock{D}, it))
end
nqudits(uc::KrausChannel) = uc.n

# noisy_instruct! is used when the matrix representation of the kraus channel is available
function noisy_instruct!(r::DensityMatrix{D,T}, x::KrausChannel, locs) where {D,T}
    return unsafe_apply!(r, KrausChannel([put(nqudits(r), locs => op) for op in x.operators]))
end
# unsafe_apply! is used when the matrix representation of the kraus channel is not available
function YaoAPI.unsafe_apply!(r::DensityMatrix{D,T}, x::KrausChannel) where {D,T}
    r0 = copy(r)
    # first
    unsafe_apply!(r, first(x.operators))
    for o in x.operators[2:end-1]
        r.state .+= unsafe_apply!(copy(r0), o).state
    end
    # last
    r.state .+= unsafe_apply!(r0, last(x.operators)).state
    return r
end

subblocks(x::KrausChannel) = x.operators
chsubblocks(x::KrausChannel, it) = KrausChannel(collect(it))
occupied_locs(x::KrausChannel) = union(occupied_locs.(x.operators)...)

function cache_key(x::KrausChannel)
    return hash(ntuple(i -> hash(x.operators[i]), length(x.operators)))
end

function Base.:(==)(lhs::KrausChannel, rhs::KrausChannel)
    return (lhs.n == rhs.n) && (lhs.operators == rhs.operators)
end

Base.adjoint(x::KrausChannel) = KrausChannel(adjoint.(x.operators))

# convert kraus channel to superop
SuperOp(x::KrausChannel) = SuperOp(ComplexF64, x)
function SuperOp(::Type{T}, x::KrausChannel{D}) where {T,D}
    superop = sum(x.operators) do op
        m = mat(T, op)
        kron(conj(m), m)
    end
    return SuperOp{D}(x.n, superop)
end

# Note: the kron of two kraus channels is kron of its components
function LinearAlgebra.kron(x::KrausChannel, y::KrausChannel)
    return KrausChannel([kron(op1, op2) for op1 in x.operators for op2 in y.operators])
end