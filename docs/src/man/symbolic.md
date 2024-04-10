```@meta
CurrentModule = YaoSym
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks, YaoArrayRegister, YaoSym
    using YaoBlocks
    using YaoArrayRegister
    using YaoSym
end
```

# Symbolic Computation

The symbolic engine of Yao is based on [SymEngine.jl](https://github.com/symengine/SymEngine.jl). It allows one to define quantum circuits with symbolic parameters and perform symbolic computation on them. Two macro/functions play a key role in the symbolic computation:
- `@vars` for defining symbolic variables
- `subs` for substituting symbolic variables with concrete values

```@repl sym
using Yao
@vars θ
circuit = chain(2, put(1=>H), put(2=>Ry(θ)))
mat(circuit)
new_circuit = subs(circuit, θ=>π/2)
mat(new_circuit)
```

## API

The following functions are for working with symbolic states.

```@docs
@ket_str
@bra_str
szero_state
```
