using YaoBase, SparseArrays, BitBasis, YaoArrayRegister, SymEngine
export @ket_str, @bra_str
export SymReg, AdjointSymReg, SymRegOrAdjointSymReg, expand
export szero_state

YaoArrayRegister._warn_type(raw::AbstractArray{Basic}) = nothing

const SymReg{B,MT} = ArrayReg{B,Basic,MT} where {MT<:AbstractMatrix{Basic}}
const AdjointSymReg{B,MT} = AdjointArrayReg{B,Basic,MT}
const SymRegOrAdjointSymReg{B,MT} = Union{SymReg{B,MT},AdjointSymReg{B,MT}}

function ket_m(s)
    v, N = parse_str(s)
    st = spzeros(Basic, 1 << N, 1)
    st[v+1] = 1
    return ArrayReg{1}(st)
end


const MAX_SYM_QUBITS = 10

function Base.show(io::IO, r::SymRegOrAdjointSymReg{1})
    if nqubits(r) < MAX_SYM_QUBITS
        print_sym_state(io, r)
    else
        summary(io, r)
        print(io, "\n    active qubits: ", nactive(r), "/", nqubits(r))
    end
end

Base.:(*)(x::SymReg{B,MT}, y::SymReg{B,MT}) where {B,MT} =
    SymReg{B,MT}(kron(state(x), state(y)))
Base.:(^)(x::SymReg{B,MT}, n::Int) where {B,MT} = SymReg{B,MT}(kron(state(x) for _ = 1:n))

Base.:(*)(x::AdjointSymReg{B,MT}, y::AdjointSymReg{B,MT}) where {B,MT} =
    adjoint(parent(x) * parent(y))
Base.:(^)(x::AdjointSymReg{B,MT}, n::Int) where {B,MT} = adjoint(parent(x)^n)

SymEngine.expand(x::SymReg{B}) where {B} = ArrayReg{B}(expand.(state(x)))

"""
    szero_state(n; nbatch=1)

Create a symbolic zero state, same as `ket"000"`, but allows you use an integer.
"""
szero_state(args...; kwargs...) = zero_state(Basic, args...; kwargs...)

function YaoBase.partial_tr(r::SymReg{B}, locs) where {B}
    orders = setdiff(1:nqubits(r), locs)
    focus!(r, orders)
    state = sum(rank3(r); dims = 2)
    relax!(r, orders)
    return ArrayReg(state)
end
