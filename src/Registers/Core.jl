# TODO: move this to document

"""
    AbstractRegister{B, T}

abstract type that registers will subtype from. `B` is the batch size, `T` is the
data type.

## Required Properties

|    Property       |                                                     Description                                       |     default      |
|:-----------------:|:-----------------------------------------------------------------------------------------------------:|:----------------:|
| `viewbatch(reg,i)`| get the view of slice in batch dimension.                                                             |                  |
| `nqubits(reg)`    | get the total number of qubits.                                                                       |                  |
| `nactive(reg)`    | get the number of active qubits.                                                                      |                  |
| `state(reg)`      | get the state of this register. It always return the matrix stored inside.                            |                  |
|   (optional)      |                                                                                                       |                  |
| `nremain(reg)`    | get the number of remained qubits.                                                                    | nqubits - nactive|
| `datatype(reg)`     | get the element type Julia should use to represent amplitude)                                         | `T`              |
| `nbatch(reg)`     | get the number of batch.                                                                              | `B`              |
| `length(reg)`     | alias of `nbatch`, for interfacing.                                                                   | `B`              |

## Required Methods

### Multiply

    *(op, reg)

define how operator `op` act on this register. This is quite useful when
there is a special approach to apply an operator on this register. (e.g
a register with no batch, or a register with a MPS state, etc.)

!!! note

    be careful, generally, operators can only be applied to a register, thus
    we should only overload this operation and do not overload `*(reg, op)`.

### Pack Address

pack `addrs` together to the first k-dimensions.

#### Example

Given a register with dimension `[2, 3, 1, 5, 4]`, we pack `[5, 4]`
to the first 2 dimensions. We will get `[5, 4, 2, 3, 1]`.

### Focus Address

    focus!(reg, range)

merge address in `range` together as one dimension (the active space).

#### Example

Given a register with dimension `(2^4)x3` and address [1, 2, 3, 4], we focus
address `[3, 4]`, will pack `[3, 4]` together and merge them as the active
space. Then we will have a register with size `2^2x(2^2x3)`, and address
`[3, 4, 1, 2]`.

## Initializers

Initializers are functions that provide specific quantum states, e.g zero states,
random states, GHZ states and etc.

    register(::Type{RT}, raw, nbatch)

an general initializer for input raw state array.

    register(::Val{InitMethod}, ::Type{RT}, ::Type{T}, n, nbatch)

init register type `RT` with `InitMethod` type (e.g `Val{:zero}`) with
element type `T` and total number qubits `n` with `nbatch`. This will be
auto-binded to some shortcuts like `zero_state`, `rand_state`.
"""
abstract type AbstractRegister{B, T} end


##############
## Interfaces
##############

"""
    nactive(x::AbstractRegister) -> Int

Return the number of active qubits.

note!!!

    Operatiors always apply on active qubits.
"""
function nactive end
nremain(r::AbstractRegister) = nqubits(r) - nactive(r)
nbatch(r::AbstractRegister{B}) where B = B
datatype(r::AbstractRegister{B, T}) where {B, T} = T
basis(r::AbstractRegister) = basis(nqubits(r))
length(reg::AbstractRegister{B}) where B = B
#eltype(reg::AbstractRegister) = typeof(first(reg))

"""
    viewbatch(r::AbstractRegister, i::Int) -> AbstractRegister{1}

Return a view of a slice from batch dimension.
"""
function viewbatch end

"""
    state(reg) -> AbstractMatrix

get the state of this register. It always return the matrix stored inside.
"""
function state end

"""
    addbit!(r::AbstractRegister, n::Int) -> AbstractRegister
    addbit!(n::Int) -> Function

addbit the register by n bits in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, addbit bits have higher indices.
If only an integer is provided, then perform lazy evaluation.
"""
function addbit! end

"""
    join(reg1::AbstractRegister, reg2::AbstractRegister) -> Register

Merge two registers together with kronecker tensor product.
"""
function join end

"""
    repeat(reg::AbstractRegister{B}, n::Int) -> AbstractRegister

Repeat register in batch dimension for `n` times.
"""
function repeat end
