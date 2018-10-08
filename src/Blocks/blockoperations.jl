#################### Filter ######################
"""
    blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}
    blockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}

tree wise filtering for blocks.
"""
blockfilter(func, blk::AbstractBlock) = blockfilter!(func, Vector{AbstractBlock}([]), blk)

function blockfilter!(func, rgs::Vector, blk::AbstractBlock)
    if func(blk) push!(rgs, blk) end
    for block in subblocks(blk)
        blockfilter!(func, rgs, block)
    end
    rgs
end

blockfilter!(func, rgs::Vector, blk::PrimitiveBlock) = func(blk) ? push!(rgs, blk) : rgs
function blockfilter!(func, rgs::Vector, blk::AbstractContainer)
    func(blk) && push!(rgs, blk)
    blockfilter!(func, rgs, block(blk))
end

import Base: collect
function collect(circuit::AbstractBlock, ::Type{BT}) where BT<:AbstractBlock
    Sequential(blockfilter!(x->x isa BT, Vector{BT}([]), circuit))
end

export traverse

"""
    traverse(blk; algorithm=:DFS) -> BlockTreeIterator

Returns an iterator that traverse through the block tree.
"""
traverse(root; algorithm=:DFS) = BlockTreeIterator(algorithm, root)

# TODO: add depth
export BlockTreeIterator

"""
    BlockTreeIterator{BT}

Iterate through the whole block tree with breadth first search.
"""
struct BlockTreeIterator{Algorithm, BT <: AbstractBlock}
    root::BT
end

BlockTreeIterator(Algorithm::Symbol, root::BT) where BT = BlockTreeIterator{Algorithm, BT}(root)

## Breadth First Search
function iterate(it::BlockTreeIterator{:BFS}, st = (q = Queue(AbstractBlock); enqueue!(q, itr.root)) )
    if isempty(st)
        nothing
    else
        node = dequeue!(st)
        enqueue_parent!(st, node)
        node, st
    end
end

function enqueue_parent!(queue::Queue, blk::AbstractContainer)
    enqueue!(queue, blk |> block)
    queue
end

function enqueue_parent!(queue::Queue, blk::CompositeBlock)
    for each in subblocks(blk)
        enqueue!(queue, each)
    end
    queue
end

function enqueue_parent!(queue::Queue, blk::AbstractBlock)
    queue
end

# Depth First Search
function iterate(it::BlockTreeIterator{:DFS}, st = AbstractBlock[it.root])
    if isempty(st)
        nothing
    else
        node = pop!(st)
        append!(st, Iterators.reverse(subblocks(node)))
        node, st
    end
end

#################### Expect and Measure ######################
"""
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector
    expect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector

expectation value of an operator.
"""
function expect end

#expect(op::AbstractBlock, reg::AbstractRegister) = sum(conj(reg |> statevec) .* (apply!(copy(reg), op) |> statevec), dims=1) |> vec
#expect(op::AbstractBlock, reg::AbstractRegister{1}) = reg'*apply!(copy(reg), op)
expect(op::AbstractBlock, reg::AbstractRegister) = reg'*apply!(copy(reg), op)

expect(op::MatrixBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec
expect(op::MatrixBlock, dm::DensityMatrix{1}) = sum(mat(op).*dropdims(dm.state, dims=3))

################### AutoDiff Circuit ###################
export gradient, backward!
"""
    backward!(circuit::MatrixBlock, δ::AbstractRegister) -> AbstractRegister

back propagate and calculate the gradient ∂f/∂θ = 2*Re(∂f/∂ψ*⋅∂ψ*/∂θ), given ∂f/∂ψ*.

Note:
Here, the input circuit should be a matrix block, otherwise the back propagate may not apply (like Measure operations).
"""
backward!(δ::AbstractRegister, circuit::MatrixBlock) = δ |> circuit'

"""
    gradient(circuit::AbstractBlock, mode::Symbol=:ANY) -> Vector

collect all gradients in a circuit, mode can be :BP/:QC/:ANY, they will collect `grad` from BPDiff/QDiff/AbstractDiff respectively.
"""
gradient(circuit::AbstractBlock, mode::Symbol=:ANY) = gradient!(circuit, Float64[], Val(mode))

function gradient!(circuit::AbstractBlock, grad, mode::Val)
    for block in subblocks(circuit)
        gradient!(block, grad, mode)
    end
    grad
end

gradient!(circuit::BPDiff, grad, mode::Val{:BP}) = push!(grad, circuit.grad)
gradient!(circuit::QDiff, grad, mode::Val{:QC}) = push!(grad, circuit.grad)
gradient!(circuit::AbstractDiff, grad, mode::Val{:ANY}) = push!(grad, circuit.grad)
