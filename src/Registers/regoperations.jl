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
    @eval function ($op)(lhs::RT, rhs::RT) where {RT <: RegOrConjReg}
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
    @eval function ($op)(lhs::RT, rhs::RT) where RT <: AbstractRegister
        ($op)(state(lhs), state(rhs))
    end
end

*(bra::ConjRegister{1}, ket::AbstractRegister{1}) = (statevec(bra) * statevec(ket))[]
*(bra::ConjRegister{1}, ket::DefaultRegister{1}) = statevec(bra) * statevec(ket)
*(bra::ConjRegister{B}, ket::AbstractRegister{B}) where B = bra .* ket

# Register Linear algebra
"""
    kron(lhs::AbstractRegister, rhs::AbstractRegister)

Merge two registers together with kronecker tensor product.
"""
function kron(lhs::RT, rhs::AbstractRegister{B}) where {B, RT <: AbstractRegister{B}}
    register(kron(state(rhs), state(lhs)), B = B)
end

import LinearAlgebra: normalize!

"""
    normalize!(r::AbstractRegister) -> AbstractRegister

Return the register with normalized state.
"""
function normalize! end
normalize!(r::DefaultRegister) = (batch_normalize!(r.state); r)

"""
    cat(regs::AbstractRegister...) -> AbstractRegister

Concatenate registers in batch dimension.
"""
cat(regs::DefaultRegister...) = register(hcat((reg.state for reg in regs)...,), B=sum(nbatch, regs))
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
