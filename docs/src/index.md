```@meta
CurrentModule = Yao
```

# Yao

*A General Purpose Quantum Computation Simulation Framework*

Welcome to [Yao](https://github.com/QuantumBFS/Yao.jl), a **Flexible**, **Extensible**, **Efficient** Framework for
Quantum Algorithm Design. **Yao** (幺) is the Chinese character for normalized but not orthogonal.

We aim to provide a powerful tool for researchers, students to study and explore quantum computing in near term
future, before quantum computer being used in large-scale.

## Installation

## Try your first Yao program

A 3 line [Quantum Fourier Transformation](https://quantumbfs.github.io/Yao.jl/latest/examples/QFT/) with [Quantum Blocks](https://quantumbfs.github.io/Yao.jl/latest/man/blocks/):

```julia
A(i, j) = control(i, j=>shift(2π/(1<<(i-j+1))))
B(n, k) = chain(n, j==k ? put(k=>H) : A(j, k) for j in k:n)
qft(n) = chain(B(n, k) for k in 1:n)
```

## Installation

Yao is a &nbsp;
<a href="https://julialang.org">
    <img src="https://julialang.org/favicon.ico" width="16em">
    Julia Language &nbsp;
</a> package. To install Yao,
please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command

To install **stable** release

```julia
add Yao
```

To install CUDA version

```
add CuYao
```

To install **current master**

```julia
add Yao#master
```

A [Python binding of Yao](https://github.com/QuantumBFS/yao-python) is also provided via [pyjulia](https://github.com/JuliaPy/pyjulia). You can
install it via the following command after you have [Julia language compiler installed](https://julialang.org/downloads/).
However, to use the full feature and power of Yao, we **highly recommend you to use it from Julia language natively**.

```sh
pip install yao-framework
```

If you have problem to install the package, please [file us an issue](https://github.com/QuantumBFS/Yao.jl/issues/new).

## Getting Started

```@contents
Pages = [
    "examples/GHZ.md",
    "examples/QFT.md",
    "examples/Grover.md",
    "examples/QCBM.md",
]
Depth = 1
```

## Manual

```@contents
Pages = [
    "man/array_registers.md",
    "man/blocks.md",
    "man/base.md",
    "man/registers.md",
    "man/extending_blocks.md",
]
Depth = 1
```
