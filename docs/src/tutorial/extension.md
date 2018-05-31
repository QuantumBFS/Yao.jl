# Writting Extensions

## Tune Existing Blocks

Suppose you have an existing method to accelerate quantum simulation.

For example you can write down the matrix form of Control-Z gate easily.
```julia
using Yao
using Yao.Intrinsics: takebit, basis
function czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) where MT<:Number
    Diagonal(map(i->MT(1)-2*(takebit(i, b1) & takebit(i, b2)), basis(num_bit)))
end
```
where the first parameter is gate type, `num_bit` is the number of qubits and `b1` and `b2` specifies control bit and controlled gate respectively.

In order to use this matrix, you can dispatch the `ControlBlock` like


```julia
import Yao: mat
mat(cb::ControlBlock{1, ZGATE, N, MT}) where {N, MT} = czgate(MT, N, cb.cbit, cb.ibit)
```

Also, you may also change the `apply!` method, otherwise it will fallback to either matrix multiplication (using `mat`) or some existing naive realization like

```julia
import Yao: apply!
function apply!(reg::Register{N}, cb::ControlBlock{1, ZGATE, N, MT})
    for i in basis(N)
    	@views reg.state[i, :] .= reg[i, :].*(MT(1)-2*(takebit(i, cb.control_qubits) & takebit(i, cb.addr)))
    end
end
```

Thanks to Julia's multiply dispatch, making things simple, right?

## Create New Blocks

### Constant Gates

You can extending the block system by overloading existing APIs.

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

### Non-parametrized PrimitiveBlocks

If your algorithm does not fit any existing blocks, you may extend block system.
For example, the reflect operation used in Grover Search (although it is in the `Boost` module now).
You may write something like

```julia
################################################
#              Grover Search Block             #
################################################
# struct and its constructors
import Yao: PrimitiveBlock
struct Reflect{N, T} <: PrimitiveBlock{N, T}
    state :: Vector{T}
end
Reflect(state::Vector{T}) where T = Reflect{log2i(length(state)), T}(state)
Reflect(psi::Register) = Reflect(statevec(psi))

import Base: show
function show(io::IO, g::Reflect{N, T}) where {N, T}
    print("Reflect(N = $N")
end
```

This is a `PrimitiveBlock` since it does not contain other blocks (leaves in the block tree).

Again, you should define how they behavior, since you don't need the matrix representation (thus can not be cached), you just overide the `apply!` function.

```julia
# NOTE: this should not be matrix multiplication based
import Yao: apply!
function apply!(r::Register, g::Reflect)
    @views r.state[:,:] .= 2* (g.state'*r.state) .* reshape(g.state, :, 1) - r.state
    r
end
# since julia does not allow call overide on AbstractGate.
(rf::Reflect)(reg::Register) = apply!(reg, rf)
```

Also, you can define the tag traits , although tag function can often fall back to `mat` analysis, it is not efficient

```julia
import Yao: isunitary, isreflexive, ishermitian
isunitary(c::Reflect) = True
isreflexive(c::Reflect) = True
ishermitian(c::Reflect) = True
```

### Parametrized Blocks

Parametrized blocks can be used in optimization problems, but it should overload `dispatch!` and `nparameters` (for a `CompositeBlock`, it should be `blocks`) functions. Let's take the `RepeatedBlock` as an example.

```julia
#################### Repeated Block ######################
import Yao: CompositeBlock, blocks
mutable struct RepeatedBlock{GT<:MatrixBlock, N, MT} <: CompositeBlock{N, MT}
    block::GT
    bits::Vector{Int}
end

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(cb::RepeatedBlock{$GGate, N, MT}) where {N, MT}
        $MATFUNC(MT, N, cb.bits)
    end
end

blocks(rb::RepeatedBlock) = [rb.block]
```

If you further requires it to be cachable, you should implement `cache`, `copy` and `hash` like

```julia
import Yao: hash, copy
function hash(gate::PhaseGate, h::UInt)
    hash(hash(gate.theta, object_id(gate)), h)
end

function copy(c::ChainBlock{N, T}) where {N, T}
    ChainBlock{N, T}([copy(each) for each in c.blocks])
end
```