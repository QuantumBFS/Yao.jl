using YaoBase: @interface

parse_block(n::Int, x::Function) = x(n)

function parse_block(n::Int, x::AbstractBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    return x
end

"""
    prewalk(f, src::AbstractBlock)

Walk the tree and call `f` once the node is visited.
"""
@interface function prewalk(f::Base.Callable, src::AbstractBlock)
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
@interface function postwalk(f::Base.Callable, src::AbstractBlock)
    for each in subblocks(src)
        postwalk(f, each)
    end
    return f(src)
end

@interface blockfilter!(f, v::Vector, blk::AbstractBlock) =
    postwalk(x -> f(x) ? push!(v, x) : v, blk)

"""
    collect_blocks(block_type, root)

Return a [`ChainBlock`](@ref) with all block of `block_type` in root.
"""
@interface collect_blocks(::Type{T}, x::AbstractBlock) where T <: AbstractBlock = blockfilter!(x->x isa T, T[], x)

"""
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector
    expect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector

expectation value of an operator.
"""
@interface expect(op::AbstractBlock, r::AbstractRegister) = r' * apply!(copy(r), op)

expect(op::AbstractBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec
expect(op::AbstractBlock, dm::DensityMatrix{1}) = sum(mat(op).*dropdims(dm.state, dims=3))
