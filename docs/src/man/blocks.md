# Blocks

**Blocks** are the basic building blocks of a quantum circuit in Yao.
It simply means a quantum operator, thus, all the blocks have matrices in principal and one can get its matrix by [`mat`](@ref). The basic blocks required to build an arbitrary quantum circuit is defined in the component package [`YaoBlocks`](@ref).

Block Tree serves as an intermediate representation for Yao to analysis, optimize the circuit, then it will be lowered to instructions like for simulations, blocks will be lowered to [`instruct!`](@ref) calls.

The structure of blocks is the same with a small type system, it consists of two basic kinds of blocks: [`CompositeBlock`](@ref) (like composite types), and [`PrimitiveBlock`](@ref) (like primitive types). By combining these two kinds of blocks together, we'll be able to
construct a quantum circuit and represent it in a tree data structure.

## Primitive Blocks

Primitive blocks are subtypes of [`PrimitiveBlock`](@ref), they are the leaf nodes in a block tree, thus primitive types do not have subtypes.

We provide the following primitive blocks:

```@autodocs
Modules = [YaoBlocks]
Filter = t ->(t isa Type && t <: YaoBlocks.PrimitiveBlock)
```

## Composite Blocks

Composite blocks are subtypes of [`CompositeBlock`](@ref), they are the composition of blocks.

We provide the following composite blocks:

```@autodocs
Modules = [YaoBlocks]
Filter = t -> t isa Type && t <: YaoBlocks.CompositeBlock
```

## APIs

```@autodocs
Modules = [YaoBlocks]
Order = [:function, :macro]
```
