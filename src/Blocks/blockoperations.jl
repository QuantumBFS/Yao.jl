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

#################### Expect and Measure ######################
"""
    expect(op::AbstractBlock, reg::AbstractRegister{1}) -> Float
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Matrix

expectation value of an operator.
"""
expect(op::AbstractBlock, reg::AbstractRegister) = (reg |> statevec)'*(copy(reg) |> op |> statevec)

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
function start(itr::BlockTreeIterator{:BFS})
    q = Queue(AbstractBlock)
    enqueue!(q, itr.root)
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

function next(itr::BlockTreeIterator{:BFS}, st::Queue)
    node = dequeue!(st)
    enqueue_parent!(st, node)
    node, st
end

function done(itr::BlockTreeIterator{:BFS}, st::Queue)
    isempty(st)
end

# Depth First Search

function start(itr::BlockTreeIterator{:DFS})
    s = AbstractBlock[]
    push!(s, itr.root)
end

function next(itr::BlockTreeIterator{:DFS}, st)
    node = pop!(st)
    append!(st, Iterators.reverse(blocks(node)))
    node, st
end

function done(itr::BlockTreeIterator{:DFS}, st)
    isempty(st)
end
