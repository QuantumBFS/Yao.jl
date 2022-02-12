using YaoBase, SparseArrays, BitBasis, YaoArrayRegister
using ..SymEngine
export @ket_str, @bra_str
export SymReg, AdjointSymReg, SymRegOrAdjointSymReg, expand
export szero_state

YaoArrayRegister._warn_type(raw::AbstractArray{Basic}) = nothing

const SymReg{D,MT} = AbstractArrayReg{D,Basic,MT} where {MT<:AbstractMatrix{Basic}}
const AdjointSymReg{D,MT} = AdjointArrayReg{D,Basic,MT}
const SymRegOrAdjointSymReg{D,MT} = Union{SymReg{D,MT},AdjointSymReg{D,MT}}

function SymReg{D,MT}(r::ArrayReg{D,<:Number}) where {D,MT<:AbstractMatrix{Basic}}
    return ArrayReg{D}(MT(Basic.(r.state)))
end
function SymReg{D,MT}(r::BatchedArrayReg{D,<:Number}) where {D,MT<:AbstractMatrix{Basic}}
    return BatchedArrayReg{D}(MT(Basic.(r.state)), r.nbatch)
end

function SymReg(r::AbstractArrayReg{D,<:Number}) where {D}
    smat = SparseMatrixCSC(Basic.(_pretty_basic.(r.state)))
    return arrayreg(SparseMatrixCSC(smat); nbatch=nbatch(r), nlevel=D)
end

_pretty_basic(x) = x
_pretty_basic(x::Real) = isinteger(x) ? Int(x) : x
function _pretty_basic(x::Complex)
    if isreal(x)
        return _pretty_basic(real(x))
    elseif iszero(real(x))
        return Basic(im)*_pretty_basic(imag(x))
    else
        return _pretty_basic(real(x)) + Basic(im) * _pretty_basic(imag(x))
    end
end

function ket_m(s)
    v, N = parse_str(s)
    st = spzeros(Basic, 1 << N, 1)
    st[v+1] = 1
    return ArrayReg(st)
end


const MAX_SYM_QUBITS = 10

for REG in [:(ArrayReg{D, Basic} where D), :(BatchedArrayReg{D, Basic} where D), :(AdjointArrayReg{D,Basic} where D)]
    @eval function Base.show(io::IO, r::$REG)
        if nqudits(r) < MAX_SYM_QUBITS
            print_sym_state(io, r)
        else
            summary(io, r)
            print(io, "\n    active qudits: ", nactive(r), "/", nqudits(r))
        end
    end
end

Base.:(*)(x::SymReg{D,MT}, y::SymReg{D,MT}) where {D,MT} = arrayreg(kron(state(x), state(y)); nlevel=D, nbatch=nbatch(x))
Base.:(*)(x::AdjointSymReg{D,MT}, y::AdjointSymReg{D,MT}) where {D,MT} =
    adjoint(parent(x) * parent(y))

Base.:(^)(x::SymReg{D,MT}, n::Int) where {D,MT} = arrayreg(kron(state(x) for _ in 1:n); nlevel=D, nbatch=nbatch(x))
Base.:(^)(x::AdjointSymReg{D,MT}, n::Int) where {D,MT} = adjoint(parent(x)^n)

SymEngine.expand(x::SymReg{D}) where {D} = arrayreg(expand.(state(x)); nlevel=D, nbatch=nbatch(x))

"""
    szero_state(n; nbatch=1)

Create a symbolic zero state, same as `ket"000"`, but allows you use an integer.
"""
szero_state(args...; kwargs...) = zero_state(Basic, args...; kwargs...)

function YaoBase.partial_tr(r::SymReg{D}, locs) where D
    orders = setdiff(1:nqudits(r), locs)
    r2 = focus!(copy(r), orders)
    state = sum(rank3(r2); dims = 2)
    return arrayreg(reshape(state, :, size(state, 3)); nbatch=nbatch(r), nlevel=D)
end
