#################### Filter ######################
"""
    blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}
    blockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}

tree wise filtering for blocks.
"""
blockfilter(func, blk::AbstractBlock) = blockfilter!(func, Vector{AbstractBlock}([]), blk)

function blockfilter!(func, rgs::Vector, blk::CompositeBlock)
    if func(blk) push!(rgs, blk) end
    for block in blocks(blk)
        blockfilter!(func, rgs, block)
    end
    rgs
end

blockfilter!(func, rgs::Vector, blk::PrimitiveBlock) = func(blk) ? push!(rgs, blk) : rgs
blockfilter!(func, rgs::Vector, blk::TagBlock) = func(parent(blk)) ? push!(rgs, parent(blk)) : rgs

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

function enqueue_parent!(queue::Queue, blk::AbstractBlock)
    for each in blocks(blk)
        enqueue!(queue, each)
    end
    queue
end

function enqueue_parent!(queue::Queue, blk::PrimitiveBlock)
    queue
end

# Depth First Search
function iterate(it::BlockTreeIterator{:DFS}, st = AbstractBlock[it.root])
    if isempty(st)
        nothing
    else
        node = pop!(st)
        append!(st, Iterators.reverse(blocks(node)))
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

expect(op::AbstractBlock, reg::AbstractRegister) = sum(conj(reg |> statevec) .* (apply!(copy(reg), op) |> statevec), dims=1) |> vec
expect(op::AbstractBlock, reg::AbstractRegister{1}) = reg'*apply!(copy(reg), op)

expect(op::MatrixBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec
expect(op::MatrixBlock, dm::DensityMatrix{1}) = sum(mat(op).*dropdims(dm.state, dims=3))
