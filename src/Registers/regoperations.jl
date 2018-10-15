###################### Linear Algebra for Registers ########################
const RegOrConjReg{B, T} = Union{ConjRegister{B, T}, AbstractRegister{B, T}}
# iterable interface
broadcastable(reg::RegOrConjReg{1}) = Ref(reg)
broadcastable(bra::ConjRegister) = [bra...]
iterate(reg::RegOrConjReg{1}, state=1) = state == 1 ? (reg, 2) : nothing
function iterate(reg::RegOrConjReg{B}, state=1) where B
    if state > B
        return nothing
    else
        viewbatch(reg, state), state+1
    end
end

# basic arithmatics
for op in [:+, :-]
    @eval function ($op)(lhs::RegOrConjReg{B}, rhs::RegOrConjReg{B}) where B
        register(($op)(state(lhs), state(rhs)))
    end
end
-(reg::RT) where RT<:RegOrConjReg = register(-state(reg))
for op in [:*, :/]
    @eval function ($op)(lhs::RT, rhs::Number) where {B, RT <: RegOrConjReg{B}}
        register(($op)(state(lhs), rhs), B=B)
    end
    if op == :*
        @eval function ($op)(lhs::Number, rhs::RT) where {B, RT <: RegOrConjReg{B}}
            register(($op)(lhs, state(rhs)), B=B)
        end
    end
end

for op in [:(==), :≈]
    @eval function ($op)(lhs::RegOrConjReg{B}, rhs::RegOrConjReg{B}) where B
        ($op)(state(lhs), state(rhs))
    end
end

*(bra::ConjRegister{1}, ket::AbstractRegister{1}) = (statevec(bra) * statevec(ket))[]
*(bra::ConjRegister{1}, ket::DefaultRegister{1}) = statevec(bra) * statevec(ket)
*(bra::ConjRegister{B}, ket::AbstractRegister{B}) where B = bra .* ket

# Register Linear algebra
"""
    join(reg1::AbstractRegister, reg2::AbstractRegister) -> Register

Merge two registers together with kronecker tensor product.
"""
function join(reg1::DefaultRegister{B, T1}, reg2::DefaultRegister{B, T2}) where {B, T1, T2}
    s1 = reg1 |> rank3
    s2 = reg2 |> rank3
    T = promote_type(T1, T2)
    state = Array{T,3}(undef, size(s1, 1)*size(s2, 1), size(s1, 2)*size(s2, 2), B)
    for b = 1:B
        @inbounds @views state[:,:,b] = kron(s2[:,:,b], s1[:,:,b])
    end
    DefaultRegister{B}(reshape(state, size(state, 1), :))
end
join(reg1::DefaultRegister{1}, reg2::DefaultRegister{1}) = DefaultRegister{1}(kron(reg2.state, reg1.state))

"""
    addbit!(r::DefaultRegister, n::Int) -> DefaultRegister
    addbit!(n::Int) -> Function

addbit the register by n bits in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, addbit bits have higher indices.
If only an integer is provided, then perform lazy evaluation.
"""
function addbit!(r::DefaultRegister{B, T}, n::Int) where {B, T}
    mat = r.state
    M, N = size(mat)
    r.state = zeros(T, M*(1<<n), N)
    r.state[1:M, :] = mat
    r
end

addbit!(n::Int) = r->addbit!(r, n)


"""
    isnormalized(reg::DefaultRegister) -> Bool

Return true if a register is normalized else false.
"""
isnormalized(reg::DefaultRegister) = all(sum(copy(reg) |> relax! |> probs, dims=1) .≈ 1)

import LinearAlgebra: normalize!

"""
    normalize!(r::AbstractRegister) -> AbstractRegister

Return the register with normalized state.
"""
function normalize! end
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

"""
    repeat(reg::DefaultRegister{B}, n::Int) -> AbstractRegister

Repeat register in batch dimension for `n` times.
"""
repeat(reg::DefaultRegister{B}, n::Int) where B = DefaultRegister{B*n}(hcat((reg.state for i=1:n)...,))

# Register Operations
"""
    fidelity(reg1::AbstractRegister, reg2::AbstractRegister) -> Vector

Return the fidelity between two states.
"""
function fidelity end

"""
    tracedist(reg1::AbstractRegister, reg2::AbstractRegister) -> Vector
    tracedist(reg1::DensityMatrix, reg2::DensityMatrix) -> Vector

trace distance.
"""
function tracedist end

include("focus.jl")
include("measure.jl")
