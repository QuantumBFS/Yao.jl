```@meta
CurrentModule = Yao.Blocks
```

# Blocks System

**Blocks** are the basic component of a quantum circuit in Yao.


# Block System

The whole framework is consist of a block system. The whole system characterize
a quantum circuit into serveral kinds of blocks. The uppermost abstract type for the whole system is [`AbstractBlock`](@ref)

![Block-System](../assets/figures/block_tree.svg)

## Composite Blocks

### Roller

[`Roller`](@ref) is a special pattern of quantum circuits. Usually is equivalent to a [`KronBlock`](@ref), but we can optimize
the computation by rotate the tensor form of a quantum state and apply each small block on it each time.

![Block-System](../assets/figures/roller.svg)

## Blocks

```@autodocs
Modules = [Yao.Blocks, Yao.Blocks.ConstGateTools]
Order   = [:module, :constant, :type, :macro, :function]
```
