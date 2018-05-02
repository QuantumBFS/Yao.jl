# Proposal for blocks

## Demo

### Native circuit construction.

![](http://demonstrations.wolfram.com/QuantumCircuitImplementingGroversSearchAlgorithm/HTMLImages/index.en/popup_1.jpg)

```julia
circuit = chain(
    kron(Hardmard for i=1:4),
    focus(4, 1:2),
    PauliX,
    focus(4, 1:4)
    control(
        4, PauliX,
        1, 2, 3,
    ),
    focus(4, 1:2),
    PauliX,
    # 1:3 active now
    focus(4, 1:3),
    kron(chain(Hardmard, PauliX) for i=1:3),
    control(
        3, PauliZ,
        1, 2,
    )
    kron(chain(PauliX, Hardmard) for i=1:3),
)
```

### Accelerate circuit evaluation with cached blocks

With its matrix form cached blocks, the process of evaluation can be accelerated
with directly calculation with its matrix form.

```julia
# A four qubit quantum circuit born machine

rotations = [rotation(4), rotation(4)]

circuit = sequence(
    cache(rotations[1], level=3),
    cache(
        kron(
            control(
                2, PauliX,
                1,
            ),
            control(
                2, PauliX,
                1,
            ),
        ),
        level=1
    ),
    focus(4, 1:3),
    control(
        1, PauliX,
        2, 3,
    )
    focus(4, 1:4),
    cache(rotations[2], level=3),
    measure(1:4, n=1000)
)

register = Register(4)
step = 1e-2

# force cache all cacheable block in the beginning
cache!(circuit, force=true)

# this trains the first rotation block
for i in 1:1000
    update!(rotations[1], (i%4, -pi/2)) # update will add parameters
    cache!(circuit) # will not re-cache next time
    negative = circuit(register)

    update!(rotations[1], (i%4, pi/2))
    cache!(circuit)
    positive = circuit(register)

    grad = grad_MMD_loss(negative, positive)
    update!(rotations[1], (i%4, grad * step))
end
```

### Different measurements

```julia
# A four qubit quantum circuit born machine

rotations = [rotation(4), rotation(4)]

pre_circuit = chain(
    cache(rotations[1], level=3),
    cache(
        kron(
            control(
                2, PauliX,
                1,
            ),
            control(
                2, PauliX,
                1,
            ),
        ),
        level=1
    ),
    focus(4, 1:3),
    control(
        1, PauliX,
        2, 3,
    )
    focus(4, 1:4),
    cache(rotations[2], level=3)
)

post_circuit = sequence(
    pre_circuit,
    remove!(4, 1:2), # this create a `RemoveBlock` (a subtype of `AbstractMeasure`)
    another_smaller_circuit,
)
```



## Types & Interface

### Methods for circuit construction

- `sequence(blocks...)`: make a `Sequence` block, this is a naive wrapper of a list of blocks. (no shape check)
- `chain(blocks...)`: chain several blocks together, it returns a `ChainBlock` and requires all its `ninput` and `noutput` is equal. See `ChainBlock` for more info.
- `kron(blocks...)` or `kron(block_with_pos::Tuple{Int, Block}...)`: combine serveal block together by kronecker product. See `KronBlock` for more info.
- `cache(block, level=1)`: cache its argument with a cache level. See `CacheBlock` for more info.
- `control(head, block, control_qubits...)`: create a controled block

NOTE: **All constructors of blocks will not be exported.**

### AbstractBlock

Abstract block supertype which blocks inherit from.

#### Prototype

```julia
abstract type AbstractBlock{N} end
```

#### Type Traits

- `ninput`: number of input qubits (default is `N`)
- `noutput`: number of output qubits (default is `N`)
- `isunitary`: check whether this block type is a unitary (default is `false`)
- `iscacheable`: check whether this block type is cacheable (default is `false`)
- `cache_type`: what kind of cache block (with which level) should be used for this block (default is `CacheBlock`)
- `ispure`: check whether this block type is a pure block (default is `false`)

#### Instance Properties

- `get_cache(block)->list`: get all cache blocks in `block`

#### Required Methods

- `apply!(register, block)->reg`: apply this block to a register, it will only have side-effect on this register.
- `update!(block, params...)->block`: scatter a set of parameters to each block, it will only have side-effect on this block (and its children).
- `cache!(block, level=1, force=false)->block`: update cache blocks with cache level less than input cache level, if there is a cached instance of block, unless `force=true`, cache will not be updated.

### PureBlock

Abstract block supertype whose subtype has a square matrix form.

#### Prototype:

```julia
abstract type PureBlock{N} <: AbstractBlock{N} end
```
#### Type Traits

- `ispure`: check whether this block type is a pure block (default is `true`)

#### Instance Properties

- `full`: get the dense matrix form of given instance
- `sparse`: get the sparse matrix form of given instance

#### Required Methods

### Concentrator

Block that concentrate given lines together.

#### Prototype:

```julia
struct Concentrator{N, M} <: AbstractBlock{N}
    line_orders::NTuple{M, Int}
end
```

`M`: number of active qubits.

#### Type Traits

- `ninput`: get the number of input qubits (`N`)
- `noutput`: get the number of output qubits (`M`)

#### Instance Properties

- `line_orders`: get what is concentrated together

#### Required Methods

- `focus(nqubits, orders...)`: get a instance of `Concentrator`

### Sequence

a naive wrapper of a sequence of blocks.

```julia
struct Sequence{N} <: AbstractBlock{N}
    list::Vector
end
```

**Exported**

- `sequence(blocks...)`: create an instance of `Sequence`.

### AbstractMeasure

Abstract block supertype which measurement block will inherit from.

#### Prototype

```julia
abstract type AbstractMeasure{N, M} <: AbstractBlock{N} end
```

### CacheBlock

abstract supertype which cache blocks will inherit from

#### Prototype

```julia
abstract type CacheBlock{N} <: PureBlock{N} end
```

### Method

- `cache!(block, level=1, force=false)` cache this block with given cache level.
- `cache(block)` create a cache block according to this block type's `cache_type` trait.

## Subtype of `PureBlock`

### CompositeBlock

abstract supertype which composite blocks will inherit from.

#### Prototype

```julia
abstract type CompositeBlock{N} <: PureBlock{N} end
```

#### Subtypes

`ChainBlock`: chain a list of blocks together, will check its input and output shape.

```julia
struct ChainBlock{N, T <: AbstractBlock{N}}
    list::Vector{T}
end
```

**Exported bindings**
- `chain(blocks...)`: create an instance of `ChainBlock` and check the shape of each block. (`ChainBlock`'s constructor won't check the shape)

`KronBlock`: fuse a list of blocks together with kronecker product

```julia
struct KronBlock{N, T <: PureBlock} <: AbstractBlock{N}
    heads::Vector{Int}
    list::Vector{T}
end
```

**exported bindings**

- `kron(blocks)` and `kron(blocks_with_pos::Tuple...)` create an instance of `KronBlock` 

### PrimitiveBlock

abstract supertype which all primitive blocks will inherit from.

#### Prototype

```julia
abstract type PrimitiveBlock{N} <: PureBlock{N} end
```

#### Type Traits

- `iscacheable`: default is `true`
- `isunitary`: default is `true`

#### Subtypes

`Gate`: block for simple gate type (`GT`) without parameters. Their matrix form is a constant matrix. Therefore, there will only be one matrix allocation no matter how many instances are created.

```julia
struct Gate{GT, N} <: PrimitiveBlock{N} end
```

**Exported bindings**:

- `PauliX, PauliY, PauliZ`
- `Hardmard`
- `CNOT`

`PhiGate`: block for phase gates

```julia
mutable struct PhiGate{T} <: PrimitiveBlock{1}
    theta::T
end
```

**Exported bindings**

- `phase(theta)`

`Rotation`: a primitive block for rotation gates (not `RotationBlock`)

```julia
mutable struct Rotation{GT, T} <: PrimitiveBlock{1}
    theta::T
end
```

**Exported bindings**

- `rotation(::Type{GT}, ::AbstractFloat) where {GT <: Union{X, Y, Z}}`

`RotationBlock`: a primitive block for arbitrary rotation: Rz Rx Rz

```julia
mutable struct RotationBlock{N, T} <: PrimitiveBlock{N}
    thetas::Vector{T} # 3N thetas
end
```

**Exported bindings**

- `rotation(::Int)`
