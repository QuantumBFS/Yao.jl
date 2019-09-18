# Variational Quantum Eigensolver

## Start

1. install [Julia 1.1](https://julialang.org/downloads/)
2. type `]` in julia REPL to enter `pkg` mode, and install packages with
```julia
pkg> add Yao KrylovKit
pkg> dev git@github.com:QuantumBFS/YaoExtensions.jl.git
```
3. run H2 example with
```bash
julia examples/VQE/H2.jl
```
