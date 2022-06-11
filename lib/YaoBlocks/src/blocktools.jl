export postwalk, prewalk, blockfilter!, blockfilter, collect_blocks, gatecount

"""
    parse_block(n, ex)

This function parse the julia object `ex` to a quantum block,
it defines the syntax of high level interfaces. `ex` can be
a function takes number of qubits `n` as input or it can be
a pair.
"""
function parse_block end

parse_block(n::Int, x::Function) = x(n)

parse_block(n::Int, ex) =
    throw(Meta.ParseError("cannot parse expression $ex, expect a pair or quantum block"))

function parse_block(n::Int, x::AbstractBlock{D}) where {D}
    n == nqudits(x) || throw(ArgumentError("number of qubits does not match: $x"))
    return x
end

# if it is a single qubit pair, parse it to put block
parse_block(n::Int, x::Pair{Int,<:AbstractBlock}) = error("got $x, do you mean put($x)?")
# infer the number of qubits if the inner function was curried
parse_block(n::Int, x::Pair{Int,<:Function}) = error("got $x, do you mean put($x)?")

# error if it is not single qubit case
function parse_block(n::Int, x::Pair)
    error(
        "please specifiy the block type of $x, consider to use concentrate for large block in local scope.",
    )
end

"""
    prewalk(f, src::AbstractBlock)

Walk the tree and call `f` once the node is visited.
"""
function prewalk(f::Base.Callable, src::AbstractBlock)
    out = f(src)
    for each in subblocks(src)
        prewalk(f, each)
    end
    return out
end

"""
    postwalk(f, src::AbstractBlock)

Walk the tree and call `f` after the children are visited.
"""
function postwalk(f::Base.Callable, src::AbstractBlock)
    for each in subblocks(src)
        postwalk(f, each)
    end
    return f(src)
end

blockfilter!(f, v::Vector, blk::AbstractBlock) = postwalk(x -> f(x) ? push!(v, x) : v, blk)

blockfilter(f, blk) = blockfilter!(f, [], blk)

"""
    collect_blocks(block_type, root)

Return a [`ChainBlock`](@ref) with all block of `block_type` in root.
"""
collect_blocks(::Type{T}, x::AbstractBlock) where {T<:AbstractBlock} =
    blockfilter!(x -> x isa T, T[], x)

#expect(op::AbstractBlock, r::AbstractRegister) = r' * apply!(copy(r), op)

#expect(op::AbstractBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec

"""
    expect(op::AbstractBlock, reg) -> Vector
    expect(op::AbstractBlock, reg => circuit) -> Vector
    expect(op::AbstractBlock, density_matrix) -> Vector

Get the expectation value of an operator, the second parameter can be a register `reg` or a pair of input register and circuit `reg => circuit`.

expect'(op::AbstractBlock, reg=>circuit) -> Pair
expect'(op::AbstractBlock, reg) -> AbstracRegister

Obtain the gradient with respect to registers and circuit parameters.
For pair input, the second return value is a pair of `gψ=>gparams`,
with `gψ` the gradient of input state and `gparams` the gradients of circuit parameters.
For register input, the return value is a register.

!!! note

    For batched register, `expect(op, reg=>circuit)` returns a vector of size number of batch as output. However, one can not differentiate over a vector loss, so `expect'(op, reg=>circuit)` accumulates the gradient over batch, rather than returning a batched gradient of parameters.
"""
function expect(op::AbstractBlock, dm::DensityMatrix)
    # NOTE: we use matrix form here because the matrix size is known to be small,
    # while applying a circuit on a reduced density matrix might take much more than constructing the matrix.
    mop = mat(op)
    return sum(transpose(dm.state) .* mop)
end

expect(op::AbstractBlock, reg::ArrayReg) = reg' * apply!(copy(reg), op)

function expect(op::AbstractBlock, reg::BatchedArrayReg)
    B = YaoArrayRegister._asint(nbatch(reg))
    ket = apply!(copy(reg), op)
    if !(reg.state isa Transpose)
        C = conj!(reshape(ket.state, :, B))
        A = reshape(reg.state, :, B)
        dropdims(sum(A .* C, dims = 1), dims = 1) |> conj
    elseif size(reg.state, 2) == B
        Na = size(reg.state, 1)
        C = conj!(reshape(ket.state.parent, B, Na))
        A = reshape(reg.state.parent, B, Na)
        dropdims(sum(A .* C, dims = 2), dims = 2) |> conj
    else
        Na = size(reg.state, 1)
        C = conj!(reshape(ket.state.parent, :, B, Na))
        A = reshape(reg.state.parent, :, B, Na)
        dropdims(sum(A .* C, dims = (1, 3)), dims = (1, 3)) |> conj
    end
end

for REG in [:ArrayReg, :BatchedArrayReg]
    @eval function expect(op::AbstractAdd, reg::$REG)
        sum(opi -> expect(opi, reg), op)
    end
    @eval function expect(op::Scale, reg::$REG)
        factor(op) * expect(content(op), reg)
    end
end

function expect(op, plan::Pair{<:AbstractRegister,<:AbstractBlock})
    expect(op, copy(plan.first) |> plan.second)
end

# obtaining Dense Matrix of a block
LinearAlgebra.Matrix(blk::AbstractBlock) = Matrix(mat(blk))

"""
    operator_fidelity(b1::AbstractBlock, b2::AbstractBlock) -> Number

Operator fidelity defined as

```math
F^2 = \\frac{1}{d^2}\\left[{\\rm Tr}(b1^\\dagger b2)\\right]
```

Here, `d` is the size of the Hilbert space. Note this quantity is independant to global phase.
See arXiv: 0803.2940v2, Equation (2) for reference.
"""
function operator_fidelity(b1::AbstractBlock, b2::AbstractBlock)
    U1 = mat(b1)
    U2 = mat(b2)
    return abs(sum(conj(U1) .* U2)) / size(U1, 1)
end

gatecount(blk::AbstractBlock) = gatecount!(blk, Dict{Type{<:AbstractBlock},Int}())

for BT in [:ChainBlock, :KronBlock, :Add, :PutBlock, :CachedBlock]
    @eval gatecount!(c::$BT, storage::AbstractDict) = (gatecount!.(c |> subblocks, Ref(storage)); storage)
end

function gatecount!(c::RepeatedBlock, storage::AbstractDict)
    k = typeof(content(c))
    n = length(c.locs)
    if haskey(storage, k)
        storage[k] += n
    else
        storage[k] = n
    end
    storage
end

# default: do not recurse
function gatecount!(c::AbstractBlock, storage::AbstractDict)
    k = typeof(c)
    storage[k] = get(storage, k, 0) + 1
    storage
end
