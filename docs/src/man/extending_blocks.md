```@meta
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks, YaoArrayRegister
    using YaoBlocks
    using YaoArrayRegister
end
```


# Extending Blocks

Blocks are defined as a sub-type system inside Julia, you could extend it by defining new Julia types by subtyping abstract types we provide. But we also provide some handy tools to help you create your own blocks.

## Define Custom Constant Blocks

Constant blocks are used quite often and in numerical simulation we would expect it to be a real constant in the program, which means it won't allocate new memory when we try to get its matrix for several times, and it won't change with parameters.

In Yao, you can simply define a constant block with [`@const_gate`](@ref), with the corresponding matrix:

```@repl
using YaoBlocks, BitBasis # hide
@const_gate Rand = rand(ComplexF64, 4, 4)
```

This will automatically create a type `RandGate{T}` and a constant binding `Rand` to the instance of `RandGate{ComplexF64}`,
and it will also bind a Julia constant for the given matrix, so when you call `mat(Rand)`, no allocation will happen.

```@repl
@allocated mat(Rand)
```

If you want to use other data type like `ComplexF32`, you could directly call `Rand(ComplexF32)`, which will create a new instance with data type `ComplexF32`.

```@repl
Rand(ComplexF32)
```

But remember this won't bind the matrix, it only binds **the matrix you give**

```@repl
@allocated mat(Rand(ComplexF32))
```

so if you want to make the matrix call `mat` for `ComplexF32` to have zero allocation as well, you need to do it explicitly.

```@repl
@const_gate Rand::ComplexF32
```

## Define Custom Blocks

Primitive blocks are the most basic block to build a quantum circuit, if a primitive block has a certain structure, like containing tweakable parameters, it cannot be defined as a constant, thus create a new type by subtyping [`PrimitiveBlock`](@ref) is necessary

```julia
using YaoBlocks

mutable struct PhaseGate{T <: Real} <: PrimitiveBlock{1}
    theta::T
end
```

If your insterested block is a composition of other blocks, you should define a [`CompositeBlock`](@ref), e.g

```julia
struct ChainBlock{N} <: CompositeBlock{N}
    blocks::Vector{AbstractBlock{N}}
end
```

Besides types, there are several interfaces you could define for a block, but don't worry, they should just error if it doesn't work.

## Define the matrix

The matrix form of a block is the minimal requirement to make a custom block functional, defining it is super simple, e.g for phase gate:

```julia
mat(::Type{T}, gate::PhaseGate) where T = exp(T(im * gate.theta)) * Matrix{Complex{T}}(I, 2, 2)
```

Or for composite blocks, you could just calculate the matrix by call `mat` on its subblocks.

```julia
mat(::Type{T}, c::ChainBlock) where T = prod(x->mat(T, x), reverse(c.blocks))
```

The rest will just work, but might be slow since you didn't define any specification for this certain block.

## Define how blocks are applied to registers

Although, having its matrix is already enough for applying a block to register, we could improve the performance or dispatch to other actions by overloading [`apply!`](@ref) interface, e.g we can use specialized instruction to make X gate (a builtin gate defined `@const_gate`) faster:

```julia
function apply!(r::ArrayReg, x::XGate)
    nactive(r) == 1 || throw(QubitMismatchError("register size $(nactive(r)) mismatch with block size $N"))
    instruct!(matvec(r.state), Val(:X), (1, ))
    return r
end
```

In Yao, this interface allows us to provide more aggressive specialization on different patterns of quantum circuits to accelerate the simulation etc.

## Define Parameters

If you want to use some member of the block to be parameters, you need to declare them explicitly

```julia
niparams(::Type{<:PhaseGate}) = 1
getiparams(x::PhaseGate) = x.theta
setiparams!(r::PhaseGate, param::Real) = (r.theta = param; r)
```

## Define Adjoint

Since blocks are actually quantum operators, it makes sense to call their `adjoint` as well. We provide [`Daggered`](@ref) for general purpose, but some blocks may have more specific transformation rules for adjoints, e.g

```julia
Base.adjoint(x::PhaseGate) = PhaseGate(-x.theta)
```

## Define Cache Keys

To enable cache, you should define `cache_key`, e.g for phase gate, we only cares about its phase, instead of the whole instance

```julia
cache_key(gate::PhaseGate) = gate.theta
```
