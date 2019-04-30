using YaoBase: @interface

parse_block(n::Int, x::Function) = x(n)

function parse_block(n::Int, x::AbstractBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    return x
end

parse_block(n::Int, x::Pair{Int, <:AbstractBlock{N}}) where N = x

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

@interface blockfilter(f, blk) = blockfilter!(f, [], blk)

"""
    collect_blocks(block_type, root)

Return a [`ChainBlock`](@ref) with all block of `block_type` in root.
"""
@interface collect_blocks(::Type{T}, x::AbstractBlock) where T <: AbstractBlock = blockfilter!(x->x isa T, T[], x)

#@interface expect(op::AbstractBlock, r::AbstractRegister) = r' * apply!(copy(r), op)

#expect(op::AbstractBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec
expect(op::AbstractBlock, dm::DensityMatrix{1}) = sum(mat(op).*dropdims(dm.state, dims=3))

"""
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector
    expect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector

expectation value of an operator.
"""
@interface function expect(op::AbstractBlock, dm::DensityMatrix{B}) where B
    mop = mat(op)
    [tr(view(dm.state,:,:,i)*mop) for i=1:B]
end

expect(op::AbstractBlock, reg::AbstractRegister{1}) = reg'*apply!(copy(reg), op)

function expect(op::AbstractBlock, reg::AbstractRegister{B}) where B
    ket = apply!(copy(reg), op)
    C = conj!(reshape(ket.state, :, B))
    A = reshape(reg.state, :, B)
    dropdims(sum(A.*C, dims=1), dims=1) |> conj
end

function expect(op::Sum, reg::AbstractRegister)
    sum(opi->expect(opi, reg), op)
end

function expect(op::Scale, reg::AbstractRegister)
    op.alpha*expect(content(op), reg)
end

expect(op::Sum, reg::AbstractRegister{1}) = invoke(expect, Tuple{Sum, AbstractRegister}, op, reg)
expect(op::Scale, reg::AbstractRegister{1}) = invoke(expect, Tuple{Scale, AbstractRegister}, op, reg)

for FUNC in [:measure!, :measure_collapseto!, :measure_remove!, :measure]
    @eval function YaoBase.$FUNC(op::AbstractBlock, reg::AbstractRegister, locs::AllLocs; kwargs...) where B
        $FUNC(eigen!(mat(op) |> Matrix), reg, locs; kwargs...)
    end
end
