# Base

The Base module of Yao is defined in [YaoBase.jl](https://github.com/QuantumBFS/YaoBase.jl), it provides:

- [the basic abstract register and its interface](@ref abstract_registers)
- quantum information related math functions
- [`@interface`](@ref) macro for drier interface definition in Yao ecosystem
- custom errors and assertion handling
- general properties, e.g [`ishermitian`](@ref), [`isunitary`](@ref), etc.
- common constants in quantum information

## Math Functions

```@autodocs
Modules = [YaoBase]
Pages = ["utils/math.jl"]
```

## General Properties

```@autodocs
Modules = [YaoBase]
Pages = ["inspect.jl"]
```

## Error and Exceptions

```@autodocs
Modules = [YaoBase]
Pages = ["error.jl"]
```

## Constants

```@eval
using Latexify, YaoBase
const_list = filter(x->x!==:Const, names(Const))
name_list = map(string, const_list)
mdtable(name_list; head=["defined constants"])
```
