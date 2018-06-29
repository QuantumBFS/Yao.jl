export ReflectBlock

"""
    ReflectBlock{N, T} <: PrimitiveBlock{N, T}

Householder reflection with respect to some target state, ``|\\psi\\rangle = 2|s\\rangle\\langle s|-1``.
"""
struct ReflectBlock{N, T} <: PrimitiveBlock{N, T}
    state :: Vector{T}
end
ReflectBlock(state::Vector{T}) where T = ReflectBlock{log2i(length(state)), T}(state)
ReflectBlock(psi::DefaultRegister) = ReflectBlock(statevec(psi))

function apply!(r::DefaultRegister, g::ReflectBlock)
    r.state[:,:] .= 2.* (g.state'*r.state) .* reshape(g.state, :, 1) - r.state
    r
end

==(A::ReflectBlock, B::ReflectBlock) = A.state == B.state
copy(r::ReflectBlock) = ReflectBlock(r.state)

mat(r::ReflectBlock) = 2*r.state*r.state' - IMatrix(length(r.state))
isreflexive(::ReflectBlock) = true
ishermitian(::ReflectBlock) = true
isunitary(::ReflectBlock) = true

function print_block(io::IO, g::ReflectBlock{N, T}) where {N, T}
    print("ReflectBlock(N = $N)")
end
