```@meta
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks, YaoArrayRegister
    using YaoBlocks
    using YaoArrayRegister
end
```

# [Registers](@id registers)
Quantum circuits process quantum states. A quantum state being processing by a quantum circuit will be stored on a quantum register.
In **Yao** we provide several types for registers. The default type for registers is the [`ArrayReg`](@ref) which is defined in [YaoArrayRegister.jl](https://github.com/QuantumBFS/YaoArrayRegister.jl).

The registers can be extended by subtyping [`AbstractRegister`](@ref) and define correspinding **register interfaces** defined in [YaoAPI.jl](https://github.com/QuantumBFS/YaoAPI.jl), which includes:

## Minimal Required Interfaces

The following interfaces are the minial required interfaces to make a register's printing work and be able to accept certain gates/blocks.

But if you don't want to work with our default printing, you could define your custom printing with [`Base.show`](https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing-1).

```@docs
YaoArrayRegister.nqubits
YaoArrayRegister.nactive
```

you can define [`instruct!`](@ref), to provide specialized instructions for the registers from plain storage types.

## Qubit Management Interfaces

```@docs
YaoArrayRegister.append_qudits!
YaoArrayRegister.reorder!
```

## Qubit Scope Management Interfaces

### LDT format
Concepturely, a wave function ``|\psi\rangle`` can be represented in a low dimentional tensor (LDT) format of order-3, L(f, r, b).

* f: focused (i.e. operational) dimensions
* r: remaining dimensions
* b: batch dimension.

For simplicity, let's ignore batch dimension for the now, we have
```math
|\psi\rangle = \sum\limits_{x,y} L(x, y, .) |j\rangle|i\rangle
```

Given a configuration `x` (in operational space), we want get the i-th bit using `(x<<i) & 0x1`, which means putting the small end the qubit with smaller index. In this representation `L(x)` will get return ``\langle x|\psi\rangle``.

!!! note

    **Why not the other convension**: Using the convention of putting 1st bit on the big end will need to know the total number of qubits `n` in order to know such positional information.

### HDT format
Julia storage is column major, if we reshape the wave function to a shape of ``2\times2\times ... \times2`` and get the HDT (high dimensional tensor) format representation H, we can use H(``x_1, x_2, ..., x_3``) to get ``\langle x|\psi\rangle``.


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

Implemented `instruct!` is listed below:

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


## References

```@autodocs
Modules = [YaoArrayRegister]
Order = [:function]
```
