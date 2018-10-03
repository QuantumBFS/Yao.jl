export TimeEvolution

"""
    TimeEvolution{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}

TimeEvolution, with GT hermitian
"""
mutable struct TimeEvolution{N, T, GT <: MatrixBlock{N, Complex{T}}} <: PrimitiveBlock{N, Complex{T}}
    H::GT
    t::T
    function TimeEvolution{N, T, GT}(H::GT, t) where {N, T, GT <: MatrixBlock{N, Complex{T}}}
        # we ignore hermitian check here for efficiency!
        #ishermitian(H) || throw(ArgumentError("Gate type $GT is not hermitian!"))
        new{N, T, GT}(H, T(t))
    end
end
TimeEvolution(H::GT, t) where {N, T, GT<:MatrixBlock{N, Complex{T}}} = TimeEvolution{N, T, GT}(H, t)

mat(te::TimeEvolution{N, T}) where {N, T} = exp(Matrix(-im*te.t*mat(te.H)))

function apply!(reg::DefaultRegister, te::TimeEvolution{N, T}) where {N, T}
    st = state(reg)
    Hmat = mat(te.H)
    LinearMap(x->apply!(register(x), te.H), size(st, 1))
    for j in 1:size(st, 2)
        st[:,j] .= expmv(-im*te.t, Hmat, st[:,j])
    end
    reg
end

adjoint(blk::TimeEvolution) = TimeEvolution(blk.H, -blk.t)

copy(te::TimeEvolution) = TimeEvolution(te.H, te.t)

# parametric interface
niparameters(::Type{<:TimeEvolution}) = 1
iparameters(x::TimeEvolution) = x.t
setiparameters!(r::TimeEvolution, params) = (r.t = first(params); r)

==(lhs::TimeEvolution{TA, GTA}, rhs::TimeEvolution{TB, GTB}) where {TA, TB, GTA, GTB} = false
==(lhs::TimeEvolution{TA, GT}, rhs::TimeEvolution{TB, GT}) where {TA, TB, GT} = lhs.t == rhs.t

function hash(gate::TimeEvolution{T, GT}, h::UInt) where {T, GT}
    hashkey = hash(objectid(gate), h)
    hashkey = hash(gate.t, hashkey)
    hashkey = hash(gate.H, hashkey)
    hashkey
end

cache_key(te::TimeEvolution) = te.t

function print_block(io::IO, te::TimeEvolution)
    print(io, "Time Evolution ", te.H, ": ", te.t)
end
