```@meta
DocTestSetup = quote
    using Yao
    using Yao: YaoBase, YaoBlocks, YaoArrayRegister
    using YaoBase
    using YaoBlocks
    using YaoArrayRegister
end
```

# [Abstract Registers](@id abstract_registers)
Quantum circuits process quantum states. A quantum state being processing by a quantum circuit will be stored on a quantum register.
In **Yao** we provide several types for registers. The default type for registers is the [`ArrayReg`](@ref) which is defined in [YaoArrayRegister.jl](https://github.com/QuantumBFS/YaoArrayRegister.jl).

The registers can be extended by subtyping [`AbstractRegister`](@ref) and define correspinding **register interfaces** defined in [YaoBase.jl](https://github.com/QuantumBFS/YaoBase.jl), which includes:

## Minimal Required Interfaces

The following interfaces are the minial required interfaces to make a register's printing work and be able to accept certain gates/blocks.

But if you don't want to work with our default printing, you could define your custom printing with [`Base.show`](https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing-1).

```@docs
YaoBase.nqubits
YaoBase.nactive
```

you can define [`instruct!`](@ref), to provide specialized instructions for the registers from plain storage types.

## Qubit Management Interfaces

```@docs
YaoBase.append_qudits!
YaoBase.reorder!
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


```@docs
YaoBase.focus!
YaoBase.relax!
```

## Measurement Interfaces

```@docs
YaoBase.measure
YaoBase.measure!
YaoBase.measure_remove!
YaoBase.measure_collapseto!
YaoBase.select!
```

## Others

```@docs
YaoBase.fidelity
YaoBase.tracedist
YaoBase.density_matrix
YaoBase.viewbatch
```
