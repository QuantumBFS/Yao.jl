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
## More
4. set your Python environment in Julia
```
julia> ENV["PYTHON"] = "... path of the python executable ..."
```
5. install [PyCall](https://github.com/JuliaPy/PyCall.jl)
```
pkg> add PyCall
pkg> build PyCall
```
6. install [OpenFermion](https://github.com/quantumlib/OpenFermion)
```bash
pip install openfermion
```
7. run H2_OpenFermion example 
```bash
julia examples/VQE/H2_OpenFermion.jl
```
