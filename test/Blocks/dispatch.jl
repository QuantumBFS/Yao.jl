using Yao
using Yao.Blocks
using DataStructures

struct BlockTreeIterator{BT <: AbstractBlock}
    root::BT
end

import Base: start, next, done

function start(itr::BlockTreeIterator)
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

function next(itr::BlockTreeIterator, st::Queue)
    node = dequeue!(st)
    enqueue_parent!(st, node)
    node, st
end

function done(itr::BlockTreeIterator, st::Queue)
    isempty(st)
end

# test
root = chain(4, kron(X, Y, Z, X), rollrepeat(X))
itr = BlockTreeIterator(root)

for each in itr
    println(typeof(each))
end
