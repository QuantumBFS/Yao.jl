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
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector
    expect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector

expectation value of an operator.
"""
function expect end
expect(op::AbstractBlock, reg::AbstractRegister) = sum(conj(reg |> statevec).*(copy(reg) |> op |> statevec), 1) |> vec
expect(op::AbstractBlock, reg::AbstractRegister{1}) = (reg |> statevec)'*(copy(reg) |> op |> statevec)

expect(op::MatrixBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, [1,2]) |> vec
expect(op::MatrixBlock, dm::DensityMatrix{1}) = sum(mat(op).*squeeze(dm.state,3))
