export MathBlock

"""
    MathBlock{L, N, T} <: PrimitiveBlock{N, T}

Block for arithmatic operations, the operation name can be specified by type parameter L.
Note the `T` parameter represents the kind of view of basis (the input format of `func`),
which should be one of `bint`, `bint_r`, `bfloat`, `bfloat_r`.
"""
struct MathBlock{L, N, T} <: PrimitiveBlock{N, Bool}
    func
    
    function MathBlock{L, N, T}(func) where {L, N, T}
        new{L, N, T}(func)
    end

    function MathBlock{L, N}(func) where {L, N}
        MathBlock{L, N, :bint}(func)
    end
end

mathop(mb::MathBlock{L, N, :bint}, b::Int) where {L, N} = mb.func(b, N)
mathop(mb::MathBlock{L, N, :bint_r}, b::Int) where {L, N} = bint_r(mb.func(bint_r(b, nbit=N), N), nbit=N)
mathop(mb::MathBlock{L, N, :bfloat}, b::Int) where {L, N} = bint(mb.func(bfloat(b, nbit=N), N), nbit=N)
mathop(mb::MathBlock{L, N, :bfloat_r}, b::Int) where {L, N} = bint_r(mb.func(bfloat_r(b, nbit=N), N), nbit=N)

function apply!(reg::DefaultRegister, mb::MathBlock{L, N}) where {L, N}
    nstate = zero(reg.state)
    for b in basis(reg)
        b2 = mathop(mb, b)
        nstate[b2+1, :] = view(reg.state, b+1, :)
    end
    reg.state = nstate
    reg
end

mat(mb::MathBlock) = applymatrix(mb)

function print_block(io::IO, pb::MathBlock{L, N, T}) where {L, N, T}
    printstyled(io, "Math: $L(x::$T, nbit=$N)"; bold=true, color=:red)
end
