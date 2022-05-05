export apply_back!, apply_back

const Rotor{D,T} = Union{RotationGate{D,T},PutBlock{D,<:Any,<:RotationGate{<:Any,T}}}

as_scalar(arr::AbstractArray{T,0}) where {T} = arr[]
as_scalar(arr) = arr

"""
    generator(rot::Rotor) -> AbstractBlock

Return the generator of rotation block.
"""
generator(rot::RotationGate) = rot.block
generator(rot::PutBlock) =
    PutBlock(rot.n, generator(rot |> content), rot |> occupied_locs)

function apply_back!(st, block::AbstractBlock, collector) #,AbstractContainer{<:PrimitiveBlock}
    out, outδ = st
    if nparameters(block) == 0
        adjblock = block'
        in = apply!(out, adjblock)
        inδ = apply!(outδ, adjblock)
        return (in, inδ)
    else
        throw(MethodError(apply_back, (st, block, collector)))
    end
end

function apply_back!(st, block::Subroutine{D}, collector) where {D}
    out, outδ = st
    focus!(out, block.locs)
    focus!(outδ, block.locs)
    apply_back!((out, outδ), content(block), collector)
    relax!(out, block.locs; to_nactive = nqudits(block))
    relax!(outδ, block.locs; to_nactive = nqudits(block))
    return (out, outδ)
end

function apply_back!(st, block::Rotor{D}, collector) where {D}
    out, outδ = st
    adjblock = block'
    backward_params!((out, outδ), block, collector)
    in = apply!(out, adjblock)
    inδ = apply!(outδ, adjblock)
    return (in, inδ)
end

function apply_back!(st, block::TimeEvolution, collector)
    out, outδ = st
    adjblock = block'

    out, outδ = st
    input = apply!(out, adjblock)
    for i=1:YaoArrayRegister._asint(nbatch(outδ))
        o = viewbatch(outδ, i)
        !all(x -> x ≈ 0.0im, o.state) && apply!(o, adjblock)
    end
    pushfirst!(collector, -sum(imag(input' * apply!(copy(outδ), block.H))))
    return (input, outδ)
end

function apply_back!(st, block::PutBlock, collector)
    out, outδ = st
    adjblock = block'
    in = apply!(out, adjblock)
    adjmat = outerprod(outδ, in)
    mat_back!(datatype(in), block, adjmat, collector)
    inδ = apply!(outδ, adjblock)
    return (in, inδ)
end

function apply_back!(st, block::KronBlock, collector)
    apply_back!(st, chain(nqudits(block), [put(loc => block[loc]) for loc in block.locs]), collector)
end

function apply_back!(st, block::ControlBlock, collector)
    out, outδ = st
    adjblock = block'
    in = apply!(out, adjblock)
    adjmat = outerprod(outδ, in)
    mat_back!(datatype(in), block, adjmat, collector)
    inδ = apply!(outδ, adjblock)
    return (in, inδ)
end

function apply_back!(st, block::Daggered, collector)
    out, outδ = st
    adjblock = block'
    in = apply!(out, adjblock)
    adjmat = outerprod(in, outδ)
    mat_back!(datatype(in), content(block), adjmat, collector)
    inδ = apply!(outδ, adjblock)
    return (in, inδ)
end

function apply_back!(st, block::Scale, collector)
    out, outδ = st
    # recoverting inputs
    if isunitary(block)
        in = apply!(out, block')
    elseif isunitary(content(block))
        in = apply!(regscale!(out, inv(factor(block))), content(block)')
    else
        @warn "rescaling a non-unitary block, call into inefficient back-propgation routine."
        in = apply!(out, matblock(inv(Matrix(block))))
    end
    # adjoint of matrix
    adjmat = outerprod(outδ, in)
    mat_back!(datatype(in), block, adjmat, collector)

    inδ = apply!(outδ, block')

    # differentiate scaling
    #if niparams(block) > 0
    #    g = dropdims(sum(conj.(state(in)) .* state(outδ), dims = (1, 2)), dims = (1, 2)) |> as_scalar
    #    pushfirst!(collector, g')
    #end
    return (in, inδ)
end

function apply_back!(st, circuit::ChainBlock, collector)
    for blk in Base.Iterators.reverse(subblocks(circuit))
        st = apply_back!(st, blk, collector)
    end
    return st
end

function apply_back!(st, circuit::AbstractAdd, collector; in)
    out, outδ = st
    adjmat = outerprod(outδ, in)
    for blk in Base.Iterators.reverse(subblocks(circuit))
        mat_back!(datatype(in), blk, adjmat, collector)
    end
    inδ = apply!(outδ, circuit')
    (in, inδ)
end

function apply_back!(st, block::RepeatedBlock{D,C}, collector) where {D,C}
    if nparameters(content(block)) == 0
        return apply!.(st, Ref(block'))
    end
    res = Any[]
    st = apply_back!(st, chain(nqudits(block), [put(loc => content(block)) for loc in block.locs]), res)
    res = dropdims(sum(reshape(res, :, C), dims = 2), dims = 2) |> as_scalar
    prepend!(collector, res)
    return st
end

# TODO: concentrator, repeat, kron
apply_back!(st, block::Measure, collector) =
    throw(MethodError(apply_back!, (st, block, collector)))

function backward_params!(st, block::Rotor, collector)
    in, outδ = st
    Σ = generator(block)
    g =
        dropdims(sum(conj.(state(in |> Σ)) .* state(outδ), dims = (1, 2)), dims = (1, 2)) |>
        as_scalar
    pushfirst!(collector, -imag(g) / 2)
    in |> Σ
    nothing
end

"""
    apply_back(st::Tuple{<:AbstractArrayReg, <:AbstractArrayReg}, block::AbstractBlock; kwargs...) -> (out, outδ), paramsδ

The backward function of `apply!`. Returns a tuple of ((input register, gradient of input register), parameter gradients)
"""
function apply_back(st::Tuple{<:AbstractArrayReg,<:AbstractArrayReg}, block::AbstractBlock; kwargs...)
    col = []
    in, inδ = apply_back!(st, block, col; kwargs...)
    (in, inδ), col
end
