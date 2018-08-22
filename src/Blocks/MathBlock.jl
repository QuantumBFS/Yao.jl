export MathBlock

"""
    MathBlock{L, N, T} <: PrimitiveBlock{N, T}

block for quantum arithmatic.
"""
struct MathBlock{L, N, T} <: PrimitiveBlock{N, T}
    func
    
    function MathBlock{L, N, T}(func) where {L, N, T}
        new{L, N, T}(func)
    end
    
    function MathBlock{L, N}(func) where {L, N}
        MathBlock{L, N, ComplexF64}(func)
    end
end

function apply!(reg::DefaultRegister, mb::MathBlock{L, N}) where {L, N}
    nstate = zero(reg.state)
    for b in basis(reg)
        b2 = mb.func(b, N)
        nstate[b2+1, :] = view(reg.state, b+1, :)
    end
    reg.state = nstate
    reg
end

mat(mb::MathBlock) = applymatrix(mb)

function print_block(io::IO, pb::MathBlock{L, N}) where {L, N}
    printstyled(io, "Math($N): $L"; bold=true, color=:red)
end
