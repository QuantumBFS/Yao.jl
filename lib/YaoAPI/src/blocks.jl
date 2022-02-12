export AbstractBlock, PrimitiveBlock, CompositeBlock, AbstractContainer, TagBlock

"""
    AbstractBlock{N, D}

Abstract type for quantum circuit blocks.
`N` is the number of qudits, while `D` is the number level in each qudit.
"""
abstract type AbstractBlock{N,D} end

"""
    PrimitiveBlock{N, D} <: AbstractBlock{N, D}

Abstract type that all primitive block will subtype from. A primitive block
is a concrete block who can not be decomposed into other blocks. All composite
block can be decomposed into several primitive blocks.

!!! note

    subtype for primitive block with parameter should implement `hash` and `==`
    method to enable key value cache.
"""
abstract type PrimitiveBlock{N,D} <: AbstractBlock{N,D} end

"""
    CompositeBlock{N, D} <: AbstractBlock{N, D}

Abstract supertype which composite blocks will inherit from. Composite blocks
are blocks composited from other [`AbstractBlock`](@ref)s, thus it is a `AbstractBlock`
as well.
"""
abstract type CompositeBlock{N,D} <: AbstractBlock{N,D} end

"""
    AbstractContainer{BT,N, D} <: CompositeBlock{N, D}

Abstract type for container block. Container blocks are blocks contain a single
block. Container block should have a
"""
abstract type AbstractContainer{BT<:AbstractBlock,N,D} <: CompositeBlock{N,D} end

"""
    TagBlock{BT, N, D} <: AbstractContainer{BT, N, D}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{BT,N,D} <: AbstractContainer{BT,N,D} end

"""
    nlevel(x)

Number of levels in each qudit.
"""
@interface nlevel

"""
    content(x)

Returns the content of `x`.
"""
@interface content


"""
    chcontent(x, blk)

Create a similar block of `x` and change its content to blk.
"""
@interface chcontent


"""
    apply!(register, block)

Apply a block (of quantum circuit) to a quantum register.
"""

@interface apply!

"""
    occupied_locs(x)

Return a tuple of occupied locations of `x`.
"""
@interface occupied_locs

"""
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.
"""
@interface subblocks

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.
"""
@interface chsubblocks

@interface print_block

"""
    mat([T=ComplexF64], blk)

Returns the matrix form of given block.
"""
@interface mat

# parameters
"""
    getiparams(block)

Returns the intrinsic parameters of node `block`, default is an empty tuple.
"""
@interface getiparams

"""
    setiparams!(block, itr)
    setiparams!(block, params...)

Set the parameters of `block`.
"""
@interface setiparams!

"""
    parameters(block)

Returns all the parameters contained in block tree with given root `block`.
"""
@interface parameters

"""
    nparameters(block) -> Int

Return number of parameters in `block`. See also [`niparams`](@ref).
"""
@interface nparameters


"""
    niparam(block) -> Int

Return number of intrinsic parameters in `block`. See also [`nparameters`](@ref).
"""
@interface niparams

"""
    iparams_eltype(block)

Return the element type of [`getiparams`](@ref).
"""
@interface iparams_eltype

"""
    parameters_eltype(x)

Return the element type of [`parameters`](@ref).
"""
@interface parameters_eltype

"""
    dispatch!(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`.

!!! note

    it will try to dispatch the parameters in collection first.
"""
@interface dispatch!

"""
    render_params(r::AbstractBlock, params)

`params` can be a number or a symbol like `:zero` and `:random`.
This function renders the input parameter to a consumable type to `r`.
"""
@interface render_params

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
@interface expect

"""
    operator_fidelity(b1::AbstractBlock, b2::AbstractBlock) -> Number

Operator fidelity defined as

```math
F^2 = \\frac{1}{d^2}\\left[{\\rm Tr}(b1^\\dagger b2)\\right]
```

Here, `d` is the size of the Hilbert space. Note this quantity is independant to global phase.
See arXiv: 0803.2940v2, Equation (2) for reference.
"""
@interface operator_fidelity

"""
    apply_back!((ψ, ∂L/∂ψ*), circuit::AbstractBlock, collector) -> AbstractRegister

back propagate and calculate the gradient ∂L/∂θ = 2*Re(∂L/∂ψ*⋅∂ψ*/∂θ), given ∂L/∂ψ*.
`ψ` is the output register, ∂L/∂ψ* should also be register type.

Note: gradients are stored in `Diff` blocks, it can be access by either `diffblock.grad` or `gradient(circuit)`.
Note2: now `apply_back!` returns the inversed gradient!
"""
@interface apply_back!

"""
    mat_back!(T, rb::AbstractBlock, adjy, collector)

Back propagate the matrix gradients.
"""
@interface mat_back!
