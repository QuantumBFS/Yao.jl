```@meta
CurrentModule = Yao.Blocks
```

# Extending Blocks

## Extending constant gate

We prepared a macro for you about constant gates like [`X`](@ref), [`Y`](@ref),
[`Z`](@ref).

Simply use [`@const_gate`](@ref).

## Extending Primitive Block with parameters

**First**, define your own block type by subtyping [`PrimitiveBlock`](@ref). And import methods you will need to overload

```@example extending-new-block
using Yao, Yao.Blocks
import Yao.Blocks: mat, dispatch!, parameters # this is the mimimal methods you will need to overload

mutable struct NewPrimitive{T} <: PrimitiveBlock{1, T}
   theta::T
end
```

**Second** define its matrix form.

```@example extending-new-block
mat(g::NewPrimitive{T}) where T = Complex{T}[sin(g.theta) 0; cos(g.theta) 0]
```

**Yao** will use this matrix to do the simulation by default. However, if you know how to directly apply your
block to a quantum register, you can also overload [`apply!`](@ref) to make your simulation become more efficient.
But this is not required.

```julia
import Yao.Blocks: apply!
apply!(r::AbstractRegister, x::NewPrimitive) = # some efficient way to simulate this block
```

**Third** If your block contains parameters, declare which member it is with [`dispatch!`](@ref)
and how to get them by [`parameters`](@ref)

```@example extending-new-block
dispatch!(g::NewPrimitive, theta) = (g.theta = theta; g)
parameters(x::NewPrimitive) = x.theta
```

The prototype of `dispatch!` is simple, just directly write the parameters as your function argument. e.g

```julia
mutable struct MultiParam{N, T} <: PrimitiveBlock{N, Complex{T}}
  theta::T
  phi::T
end
```

just write:

```julia
dispatch!(x::MultiParam, theta, phi) = (x.theta = theta; x.phi = phi; x)
```

or maybe your block contains a vector of parameters:

```julia
mutable struct VecParam{N, T} <: PrimitiveBlock{N, T}
  params::Vector{T}
end
```

just write:

```julia
dispatch!(x::VecParam, params) = (x.params .= params; x)
```

be careful, the assignment should be in-placed with `.=` rather than `=`.

If the number of parameters in your new block is fixed, we recommend you to declare this with a type
trait [`nparameters`](@ref):

```@example extending-new-block
import Yao.Blocks: nparameters
nparameters(::Type{<:NewPrimitive}) = 1
```

But it is OK if you do not define this trait, **Yao** will find out how many parameters you have dynamically.

**Fourth** If you want to enable cache of this new block, you have to define your own cache_key. usually just use your parameters
as the key if you want to cache the matrix form of different parameters, which will accelerate your simulation with a cost of larger
memory allocation. You can simply define it with [`cache_key`](@ref)

```@example extending-new-block
import Yao.Blocks: cache_key
cache_key(x::NewPrimitive) = x.theta
```

## Extending Composite Blocks

Composite blocks are blocks that are able to contain other blocks. To define a new composite block
you only need to define your new type as a subtype of [`CompositeBlock`](@ref), and define a new method
called [`blocks`](@ref) which will provide an iterator that iterates the blocks contained by this composite
block.

## Custom Pretty Printing

The whole quantum circuit is represented as a tree in the block system. Therefore, we print a block as a tree.
To define your own syntax to print, simply overloads the [`print_block`](@ref) method. Then it will appears in
the block tree syntax automatically.

```julia
print_block(io::IO, block::MyBlockType)
```

## Adding Operator Traits to Your Blocks
A gate `G` can have following traits

* [`isunitary`](@ref) - ``G^\dagger G = \mathbb{1}``
* [`isreflexive`](@ref) - ``GG = \mathbb{1}``
* [`ishermitian`](@ref) - ``G^\dagger = G``

If `G` is a [`MatrixBlock`](@ref), these traits can fall back to using [`mat`](@ref) method albiet not efficient.
If you can know these traits of a gate clearly, you can define them by hand to improve performance.

These traits are useful, e.g. a [`RotationGate`](@ref) defines an SU(2) rotation, which requires its generator both hermitian a reflexive so that ``R_G(\theta) = \cos\frac{\theta}{2} - i\sin\frac{\theta}{2} G``, so that you can use ``R_{\rm X}`` and ``R_{\rm CNOT}`` but not ``R_{\rm R_X(0.3)}``.

## Adding Tags to Your Blocks

A tag refers to

* [`Daggered`](@ref) - ``G^\dagger``
    We use `Base.adjoint(G)` to generate a daggered block.

    * If a block is hermitian, do nothing,
    * For many blocks, e.g. `Rx(0.3)`, we can still define some rule like `Base.adjoint(r::RotationBlock) = (res = copy(r); res.theta = -r.theta; res)`,
    * if even simple rule does not exist, its [`mat`](@ref) function will fall back to `mat(G)'`.

* [`CachedBlock`](@ref) - the matrix of this block under current parameter will be stored in cache server for future use.

    `G |> cache` can be useful when you are trying to compile a block into a reuseable matrix, to use cache, you should define [`cache_key`](@ref).
