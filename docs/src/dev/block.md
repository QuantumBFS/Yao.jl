# Block System

The whole framework is consist of a block system. The whole system characterize
a quantum circuit into serveral kinds of blocks. The uppermost abstract type for the whole system is `AbstractBlock`

## PureBlock

```@docs
Yao.MatrixBlock
```

## Primitive Block

```@docs
Yao.PrimitiveBlock
```

## Composite Block

```@docs
Yao.CompositeBlock
```

## MeasureBlock

```@docs
Yao.AbstractMeasure
```

## Concentrator

```@docs
Yao.Concentrator
```

![concentrator](../assets/figures/blockfocus.png)

## Sequence

```@docs
Yao.Sequence
```

# User Defined Block

You can extending the block system by overloading existing APIs.

## Extending Constant Gates

Extending constant gate is very simple:

```@example user_defined_constant
using Yao
import Yao: Gate, GateType, sparse, nqubits
# define the number of qubits
nqubits(::Type{GateType{:CNOT}}) = 2
# define its matrix form
sparse(::Gate{2, GateType{:CNOT}, T}) where T = T[1 0 0 0;0 1 0 0;0 0 0 1;0 0 1 0]
```

Then you get a constant CNOT gate

```@example user_defined_constant
g = gate(:CNOT)
sparse(g)
```

## Extending a Primitive Block

Primitive blocks are very useful when you want to accelerate a specific oracle. For example,
we can accelerate a Grover search oracle by define a custom subtype of `PrimitiveBlock`.

```julia
using Yao
import Yao: PrimitiveBlock, apply!, Register

struct GroverSearch{N, T} <: PrimitiveBlock{N, T}
end

# define how you want to simulate this oracle
function apply!(reg::Register, oracle::GroverSearch)
    # a fast implementation of Grover search
end

# define its matrix form
sparse(oracle::GroverSearch{N, T}) where {N, T} = grover_search_matrix_form(T, N)
```
