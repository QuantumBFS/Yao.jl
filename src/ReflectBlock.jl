export ReflectBlock

"""
    ReflectBlock{N, T} <: PrimitiveBlock{N, T}

Householder reflection with respect to some target state, ``|\\psi\\rangle = 2|s\\rangle\\langle s|-1``.
"""
struct ReflectBlock{N, T} <: PrimitiveBlock{N, T}
    psi :: DenseRegister{1, T}
end
ReflectBlock(psi::DenseRegister{1, T}) where T = ReflectBlock{nqubits(psi), T}(psi)
ReflectBlock(state::Vector{T}) where T = ReflectBlock(DenseRegister(state))

function apply!(r::DenseRegister, g::ReflectBlock)
    v = state(g.psi)
    r.state[:, :] .= 2 .* (v' * r.state) .* v - r.state
    r
end

Base.:(==)(A::ReflectBlock, B::ReflectBlock) = A.psi == B.psi
Base.copy(r::ReflectBlock) = ReflectBlock(r.psi)

mat(r::ReflectBlock) = (v = statevec(r.psi); 2 * v * v' - IMatrix(length(v)))
YaoBase.isreflexive(::ReflectBlock) = true
YaoBase.ishermitian(::ReflectBlock) = true
YaoBase.isunitary(::ReflectBlock) = true

function print_block(io::IO, g::ReflectBlock{N, T}) where {N, T}
    print(io, "ReflectBlock(N = $N)")
end
