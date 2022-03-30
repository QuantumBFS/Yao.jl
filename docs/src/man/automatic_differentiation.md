# Automatic Differentiation

Yao currently contains builtin automatic differentiation engine (an operator overloading based)
especially for quantum circuits. It uses the reversible context of quantum computation to optimize
the performance during simulation, thus you may find this is way faster than any other AD engine
at the moment.

## Builtin Reverse mode AD engine for simulation

As for expectation, the usage is pretty simple, since the evluation of expectations are just

```julia
expect(H, rand_state(10)=>circuit)
```

to get the gradients, simply add an adjoint

```julia
expect'(H, rand_state(10)=>circuit)
```

which will return the pair of gradients, one is the gradient of input register and
the other is the gradient of circuit parameters.

## Integration with General purpose AD engine
The builtin AD engine for Yao only provides the differentiation of quantum circuits, but you can plug it into a general AD engine, such as [Zygote](https://github.com/FluxML/Zygote.jl), since we have ported these rules to [ChainRules](https://github.com/JuliaDiff/ChainRules.jl).

## APIs

```@autodocs
Modules = [YaoBlocks.AD]
Order = [:function, :macro]
```
