export AbstractBlock, PrimitiveBlock, CompositeBlock, AbstractContainer, TagBlock

const COMMON_OPTIONAL_METHODS = """
- [`nlevel`](@ref).
- [`getiparams`](@ref).
- [`setiparams`](@ref).
- [`parameters`](@ref).
- [`nparameters`](@ref).
- [`iparams_eltype`](@ref).
- [`parameters_eltype`](@ref).
- [`dispatch!`](@ref).
- [`render_params`](@ref).
- [`apply_back!`](@ref).
- [`mat_back!`](@ref).
"""

"""
    AbstractBlock{D}

Abstract type for quantum circuit blocks.
while `D` is the number level in each qudit.

### Required Methods

- [`apply!`](@ref).
- [`mat`](@ref).
- [`occupied_locs`](@ref).
- [`print_block`](@ref)

### Optional Methods

- [`content`](@ref)
- [`chcontent`](@ref)
- [`subblocks`](@ref).
- [`chsubblocks`](@ref).
- `Base.hash`
- `Base.:(==)`
$COMMON_OPTIONAL_METHODS
"""
abstract type AbstractBlock{D} end

"""
    PrimitiveBlock{D} <: AbstractBlock{D}

Abstract type that all primitive block will subtype from. A primitive block
is a concrete block who can not be decomposed into other blocks. All composite
block can be decomposed into several primitive blocks.

!!! note

    subtype for primitive block with parameter should implement `hash` and `==`
    method to enable key value cache.

### Required Methods

- [`apply!`](@ref)
- [`mat`](@ref)
- [`print_block`](@ref)
- `Base.hash`
- `Base.:(==)`

### Optional Methods

- [`nlevel`](@ref).
- [`getiparams`](@ref).
- [`setiparams`](@ref).
- [`parameters`](@ref).
- [`nparameters`](@ref).
- [`iparams_eltype`](@ref).
- [`parameters_eltype`](@ref).
- [`dispatch!`](@ref).
- [`render_params`](@ref).
- [`apply_back!`](@ref).
- [`mat_back!`](@ref).
"""
abstract type PrimitiveBlock{D} <: AbstractBlock{D} end

"""
    CompositeBlock{D} <: AbstractBlock{D}

Abstract supertype which composite blocks will inherit from. Composite blocks
are blocks composited from other [`AbstractBlock`](@ref)s, thus it is a `AbstractBlock`
as well.

### Required Methods

- [`apply!`](@ref)
- [`mat`](@ref)
- [`occupied_locs`](@ref).
- [`subblocks`](@ref).
- [`chsubblocks`](@ref).

### Optional Methods

- [`nlevel`](@ref).
- [`getiparams`](@ref).
- [`setiparams`](@ref).
- [`parameters`](@ref).
- [`nparameters`](@ref).
- [`iparams_eltype`](@ref).
- [`parameters_eltype`](@ref).
- [`dispatch!`](@ref).
- [`render_params`](@ref).
- [`apply_back!`](@ref).
- [`mat_back!`](@ref).
"""
abstract type CompositeBlock{D} <: AbstractBlock{D} end

"""
    AbstractContainer{BT,D} <: CompositeBlock{D}

Abstract type for container block. Container blocks are blocks contain a single
block.

### Required Methods

- [`apply!`](@ref)
- [`mat`](@ref)
- [`content`](@ref)
- [`chcontent`](@ref)
- [`occupied_locs`](@ref).

### Optional Methods

$COMMON_OPTIONAL_METHODS
"""
abstract type AbstractContainer{BT<:AbstractBlock,D} <: CompositeBlock{D} end

"""
    TagBlock{BT, D} <: AbstractContainer{BT, D}

`TagBlock` is a special kind of Container block, it forwards most of the methods
but tag the block with some extra information.
"""
abstract type TagBlock{BT,D} <: AbstractContainer{BT,D} end

"""
    nlevel(x)

Number of levels in each qudit.

### Examples

```jldoctest; setup=:(using Yao)
julia> nlevel(X)
2
```
"""
@interface nlevel

"""
    content(x) -> block

Returns the content of `x`, this is a specific API for [`AbstractContainer`](@ref)
that returns a block.

### Examples

```jldoctest; setup=:(using Yao)
julia> content(2.0 * X)
X
```
"""
@interface content


"""
    chcontent(x, blk) -> block

Create a similar block of `x` and change its content to blk.

### Examples

```jldoctest; setup=:(using Yao)
julia> chcontent(2.0 * X, Y)
[scale: 2.0] Y
```
"""
@interface chcontent

"""
    apply!(register, block)

Apply a block (of quantum circuit) to a quantum register.

!!! note

    to overload `apply!` for a new block, please overload the
    [`unsafe_apply!`](@ref) function with same interface. Then
    the `apply!` interface will do the size checks on inputs
    automatically.

### Examples

```jldoctest; setup=:(using Yao)
julia> r = zero_state(2)
ArrayReg{2, ComplexF64, Array...}
    active qubits: 2/2
    nlevel: 2

julia> apply!(r, put(2, 1=>X))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 2/2
    nlevel: 2

julia> measure(r;nshots=10)
10-element Vector{DitStr{2, 2, Int64}}:
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
 01 ₍₂₎
```
"""
@interface apply!

"""
    unsafe_apply!(r, block)

Similar to [`apply!`](@ref), but will not check the size of the
register and block, this is mainly used for overloading new blocks,
use at your own risk.
"""
@interface unsafe_apply!

"""
    occupied_locs(x)

Return a tuple of occupied locations of `x`.

### Examples

```jldoctest; setup=:(using Yao)
julia> occupied_locs(kron(5, 1=>X, 3=>X))
(1, 3)

julia> occupied_locs(kron(5, 1=>X, 3=>I2))
(1,)
```
"""
@interface occupied_locs

"""
    subblocks(x)

Returns an iterator of the sub-blocks of a composite block. Default is empty.

### Examples

```jldoctest; setup=:(using Yao)
julia> subblocks(chain(X, Y, Z))
3-element Vector{AbstractBlock{2}}:
 X
 Y
 Z
```
"""
@interface subblocks

"""
    chsubblocks(composite_block, itr)

Change the sub-blocks of a [`CompositeBlock`](@ref) with given iterator `itr`.

### Examples

```jldoctest; setup=:(using Yao)
julia> chsubblocks(chain(X, Y, Z), [Z, Z])
nqubits: 1
chain
├─ Z
└─ Z
```
"""
@interface chsubblocks

"""
    print_block(io, block)

Define how blocks are printed as text in one line.

### Examples

```jldoctest; setup=:(using Yao)
julia> print_block(stdout, X)
X

julia> print_block(stdout, put(2, 1=>X))
put on (1)
```
"""
@interface print_block

"""
    mat([T=ComplexF64], blk)

Returns the most compact matrix form of given block, e.g

### Examples

```jldoctest; setup=:(using Yao)
julia> mat(X)
2×2 LuxurySparse.SDPermMatrix{ComplexF64, Int64, Vector{ComplexF64}, Vector{Int64}}:
 0.0+0.0im  1.0+0.0im
 1.0+0.0im  0.0+0.0im

julia> mat(Float64, X)
2×2 LuxurySparse.SDPermMatrix{Float64, Int64, Vector{Float64}, Vector{Int64}}:
 0.0  1.0
 1.0  0.0

julia> mat(kron(X, X))
4×4 LuxurySparse.SDPermMatrix{ComplexF64, Int64, Vector{ComplexF64}, Vector{Int64}}:
 0.0+0.0im  0.0+0.0im  0.0+0.0im  1.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im

julia> mat(kron(X, X) + put(2, 1=>X))
4×4 SparseMatrixCSC{ComplexF64, Int64} with 8 stored entries:
     ⋅      1.0+0.0im      ⋅      1.0+0.0im
 1.0+0.0im      ⋅      1.0+0.0im      ⋅
     ⋅      1.0+0.0im      ⋅      1.0+0.0im
 1.0+0.0im      ⋅      1.0+0.0im      ⋅    
```
"""
@interface mat

# parameters
"""
    getiparams(block)

Returns the intrinsic parameters of node `block`, default is an empty tuple.

### Examples

```jldoctest; setup=:(using Yao)
julia> getiparams(Rx(0.1))
0.1
```
"""
@interface getiparams

"""
    setiparams!(block, itr)
    setiparams!(block, params...)

Set the parameters of `block`.

### Examples

```jldoctest; setup=:(using Yao)
julia> setiparams!(Rx(0.1), 0.2)
rot(X, 0.2)
```
"""
@interface setiparams!

"""
    parameters(block)

Returns all the parameters contained in block tree with given root `block`.

### Examples

```jldoctest; setup=:(using Yao)
julia> parameters(chain(Rx(0.1), Rz(0.2)))
2-element Vector{Float64}:
 0.1
 0.2
```
"""
@interface parameters

"""
    nparameters(block) -> Int

Return number of parameters in `block`. See also [`niparams`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> nparameters(chain(Rx(0.1), Rz(0.2)))
2
```
"""
@interface nparameters


"""
    niparam(block) -> Int

Return number of intrinsic parameters in `block`. See also [`nparameters`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> niparams(Rx(0.1))
1
```
"""
@interface niparams

"""
    iparams_eltype(block)

Return the element type of [`getiparams`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> iparams_eltype(Rx(0.1))
Float64
```
"""
@interface iparams_eltype

"""
    parameters_eltype(x)

Return the element type of [`parameters`](@ref).

### Examples

```jldoctest; setup=:(using Yao)
julia> parameters_eltype(chain(Rx(0.1), Rz(0.1f0)))
Float64
```
"""
@interface parameters_eltype

"""
    dispatch!(x::AbstractBlock, collection)

Dispatch parameters in collection to block tree `x`.

### Arguments

- `x`: the block to dispatch parameters on.
- `collection`: a collection of parameters, e.g a list of numbers,
    also supports `:zero` and `:random`, here `:random` is equivalent
    to `rand(nparameters(x))`.

!!! note
    it will try to dispatch the parameters in collection first.

### Examples

```jldoctest; setup=:(using Yao)
julia> dispatch!(chain(Rx(0.1), Rz(0.1)), [0.2, 0.3])
nqubits: 1
chain
├─ rot(X, 0.2)
└─ rot(Z, 0.3)

julia> dispatch!(chain(Rx(0.1), Rz(0.2)), :zero)
nqubits: 1
chain
├─ rot(X, 0.0)
└─ rot(Z, 0.0)
```
"""
@interface dispatch!

"""
    render_params(r::AbstractBlock, params)

This function renders the input parameter to a consumable type to `r`.
`params` can be a number or a symbol like `:zero` and `:random`.

### Examples

```jldoctest; setup=:(using Yao)
julia> collect(render_params(Rx(0.1), :zero))
1-element Vector{Float64}:
 0.0
```
"""
@interface render_params

"""
    expect(op::AbstractBlock, reg) -> Vector
    expect(op::AbstractBlock, reg => circuit) -> Vector
    expect(op::AbstractBlock, density_matrix) -> Vector

Get the expectation value of an operator, the second parameter
can be a register `reg` or a pair of input register and circuit `reg => circuit`.

    expect'(op::AbstractBlock, reg=>circuit) -> Pair
    expect'(op::AbstractBlock, reg) -> AbstracRegister

Obtain the gradient with respect to registers and circuit parameters.
For pair input, the second return value is a pair of `gψ=>gparams`,
with `gψ` the gradient of input state and `gparams` the gradients of circuit parameters.
For register input, the return value is a register.

!!! note

    For batched register, `expect(op, reg=>circuit)` returns a vector of size number of batch as output. However, one can not differentiate over a vector loss, so `expect'(op, reg=>circuit)` accumulates the gradient over batch, rather than returning a batched gradient of parameters.

### Examples

```jldoctest; setup=:(using Yao)
julia> r = normalize!(product_state(bit"11") + product_state(bit"00"))
ArrayReg{2, ComplexF64, Array...}
    active qubits: 2/2
    nlevel: 2

julia> op = chain(2, put(1=>H), put(2=>X))
nqubits: 2
chain
├─ put on (1)
│  └─ H
└─ put on (2)
   └─ X


julia> expect(op, r)
0.7071067811865474 + 0.0im
```
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

### Examples

```jldoctest; setup=:(using Yao)
julia> operator_fidelity(X, X)
1.0

julia> operator_fidelity(X, Z)
0.0
```
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

####################### Operator properties ###############
"""
    isunitary(op) -> Bool

check if this operator is a unitary operator.
"""
@interface isunitary

"""
    isreflexive(op) -> Bool

check if this operator is reflexive.
"""
@interface isreflexive

"""
    iscommute(ops...) -> Bool

check if operators are commute.
"""
@interface iscommute

"""
    isdiagonal(operator_or_mat)

Return true if the matrix representation of the input operator/matrix has the `Diagonal` type or `IMatrix` type.
It is used to speed up the time evolution and operator measurement.
"""
@interface isdiagonal
