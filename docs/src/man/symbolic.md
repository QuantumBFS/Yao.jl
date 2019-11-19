```@meta
DocTestSetup = quote
    using Yao, YaoBase, YaoBlocks, YaoArrayRegister, YaoSym
end
```
# Symbolic Computation
Yao also supports symbolic computation. The backend is implemented via [SymEngine](https://github.com/symengine/SymEngine.jl)
at [YaoSym](https://github.com/QuantumBFS/YaoSym.jl).

## APIs

```@autodocs
Modules = [YaoSym]
Order = [:function, :macro]
```
