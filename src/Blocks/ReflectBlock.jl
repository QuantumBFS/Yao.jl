export ReflectBlock

"""
    ReflectBlock{N, T} <: PrimitiveBlock{N, T}

Householder reflection with respect to some target state, ``|\\psi\\rangle = 2|s\\rangle\\langle s|-1``.
"""
struct ReflectBlock{N, T} <: PrimitiveBlock{N, T}
    psi :: DefaultRegister{1, T}
end
ReflectBlock(psi::DefaultRegister{1, T}) where T = ReflectBlock{nqubits(psi), T}(psi)
ReflectBlock(state::Vector{T}) where T = ReflectBlock(register(state))

function apply!(r::DefaultRegister, g::ReflectBlock)
    v = state(g.psi)
    r.state[:, :] .= 2 .* (v' * r.state) .* v - r.state
    r
end

==(A::ReflectBlock, B::ReflectBlock) = A.psi == B.psi
copy(r::ReflectBlock) = ReflectBlock(r.psi)

mat(r::ReflectBlock) = (v = statevec(r.psi); 2 * v * v' - IMatrix(length(v)))
isreflexive(::ReflectBlock) = true
ishermitian(::ReflectBlock) = true
isunitary(::ReflectBlock) = true

function print_block(io::IO, g::ReflectBlock{N, T}) where {N, T}
    print("ReflectBlock(N = $N)")
end
