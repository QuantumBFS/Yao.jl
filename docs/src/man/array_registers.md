```@meta
CurrentModule = YaoArrayRegister
DocTestSetup = quote
    using Yao, YaoBase, YaoBlocks, YaoArrayRegister
end
```

# Array Registers

We provide [`ArrayReg`](@ref) as built in register type for simulations. It is a simple wrapper of a Julia array, e.g on CPU, we use `Array` by default and on CUDA devices we could use `CuArray`. You don't have to define your custom array type if the storage is array based.

## Constructors

```@docs
ArrayReg
```

We define some shortcuts to create simulated quantum states easier:

```@docs
product_state
zero_state
rand_state
uniform_state
oneto
repeat
```

## Properties

You can access the storage of an [`ArrayReg`](@ref) with:

```@docs
state
statevec
relaxedvec
hypercubic
rank3
```

## Operations

We defined basic arithmatics for [`ArrayReg`](@ref), besides since we do not garantee
normalization for some operations on [`ArrayReg`](@ref) for simulation, [`normalize!`](@ref) and 
[`isnormalized`](@ref) is provided to check and normalize the simulated register.

```@docs
normalize!
isnormalized
```

## Specialized Instructions

We define some specialized instruction by specializing [`instruct!`](@ref) to improve the performance for simulation and dispatch them with multiple dispatch.

<!-- Implemented `instruct!` is listed below: -->

## Measurement

Simulation of measurement is mainly achieved by sampling and projection.

#### Sample

Suppose we want to measure operational subspace, we can first get
```math
p(x) = \|\langle x|\psi\rangle\|^2 = \sum\limits_{y} \|L(x, y, .)\|^2.
```
Then we sample an ``a\sim p(x)``. If we just sample and don't really measure (change wave function), its over.

#### Projection
```math
|\psi\rangle' = \sum_y L(a, y, .)/\sqrt{p(a)} |a\rangle |y\rangle
```

Good! then we can just remove the operational qubit space since `x` and `y` spaces are totally decoupled and `x` is known as in state `a`, then we get

```math
|\psi\rangle'_r = \sum_y l(0, y, .) |y\rangle
```

where `l = L(a:a, :, :)/sqrt(p(a))`.


## Others

```@autodocs
Modules = [YaoArrayRegister]
Order = [:function]
```
