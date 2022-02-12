using YaoBase, SparseArrays, BitBasis, YaoArrayRegister
using ..SymEngine
export @ket_str, @bra_str
export SymReg, AdjointSymReg, SymRegOrAdjointSymReg, expand
export szero_state

YaoArrayRegister._warn_type(raw::AbstractArray{Basic}) = nothing

const SymReg{B,D,MT} = ArrayReg{B,D,Basic,MT} where {MT<:AbstractMatrix{Basic}}
const AdjointSymReg{B,D,MT} = AdjointArrayReg{B,D,Basic,MT}
const SymRegOrAdjointSymReg{B,D,MT} = Union{SymReg{B,D,MT},AdjointSymReg{B,D,MT}}

function SymReg{B,D,MT}(r::ArrayReg{B,D,<:Number}) where {B,D,MT<:AbstractMatrix{Basic}}
    return ArrayReg{B,D,Basic,MT}(MT(Basic.(r.state)))
end

function SymReg(r::ArrayReg{B,D,<:Number}) where {B,D}
    smat = SparseMatrixCSC(Basic.(_pretty_basic.(r.state)))
    return ArrayReg{B,D,Basic,SparseMatrixCSC{Basic,Int}}(SparseMatrixCSC(smat))
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
    return ArrayReg{1}(st)
end


const MAX_SYM_QUBITS = 10

function Base.show(io::IO, r::SymRegOrAdjointSymReg{1})
    if nqudits(r) < MAX_SYM_QUBITS
        print_sym_state(io, r)
    else
        summary(io, r)
        print(io, "\n    active qudits: ", nactive(r), "/", nqudits(r))
    end
end

Base.:(*)(x::SymReg{B,D,MT}, y::SymReg{B,D,MT}) where {B,D,MT} = SymReg{B,D,MT}(kron(state(x), state(y)))
Base.:(*)(x::AdjointSymReg{B,D,MT}, y::AdjointSymReg{B,D,MT}) where {B,D,MT} =
    adjoint(parent(x) * parent(y))

Base.:(^)(x::SymReg{B,D,MT}, n::Int) where {B,D,MT} = SymReg{B,D,MT}(kron(state(x) for _ in 1:n))
Base.:(^)(x::AdjointSymReg{B,D,MT}, n::Int) where {B,D,MT} = adjoint(parent(x)^n)

SymEngine.expand(x::SymReg{B,D}) where {B,D} = ArrayReg{B,D}(expand.(state(x)))

"""
    szero_state(n; nbatch=1)

Create a symbolic zero state, same as `ket"000"`, but allows you use an integer.
"""
szero_state(args...; kwargs...) = zero_state(Basic, args...; kwargs...)

function YaoBase.partial_tr(r::SymReg{B}, locs) where {B}
    orders = setdiff(1:nqudits(r), locs)
    focus!(r, orders)
    state = sum(rank3(r); dims = 2)
    relax!(r, orders)
    return ArrayReg(state)
end
