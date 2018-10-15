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

############## Reordering #################
"""
    reorder!(reg::AbstractRegister, order) -> AbstractRegister
    reorder!(orders::Int...) -> Function    # currified

Reorder the lines of qubits, it also works for array.
"""
function reorder!(reg::DefaultRegister, orders)
    for i in 1:size(reg.state, 2)
        reg.state[:,i] = reorder(reg.state[:, i], orders)
    end
    reg
end
reorder!(orders::Int...) = reg::DefaultRegister -> reorder!(reg, [orders...])

"""
    invorder!(reg::AbstractRegister) -> AbstractRegister

Inverse the order of lines inplace.
"""
invorder!(reg::DefaultRegister) = reorder!(reg, collect(nactive(reg):-1:1))

"""
    reset!(reg::AbstractRegister, val::Integer=0) -> AbstractRegister

`reset!` reg to default value.
"""
function reset!(reg::DefaultRegister; val::Integer=0)
    reg.state .= 0
    @inbounds reg.state[val+1,:] .= 1
    reg
end

function fidelity(reg1::DefaultRegister{B}, reg2::DefaultRegister{B}) where B
    state1 = reg1 |> rank3
    state2 = reg2 |> rank3
    size(state1) == size(state2) || throw(DimensionMismatch("Register size not match!"))
    # 1. pure state
    if size(state1, 2) == 1
        return map(b->fidelity_pure(state1[:,1,b], state2[:,1,b]), 1:B)
    else
        return map(b->fidelity_mix(state1[:,:,b], state2[:,:,b]), 1:B)
    end
end

function tracedist(reg1::DefaultRegister{B}, reg2::DefaultRegister{B}) where B
    size(reg1.state, 2) == B ? sqrt.(1 .- fidelity(reg1, reg2).^2) : throw(ArgumentError("trace distance for non-pure state is not defined!"))
end

include("focus.jl")
include("measure.jl")
