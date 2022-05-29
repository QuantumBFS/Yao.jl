```@meta
DocTestSetup = quote
    using Yao
    using Yao: YaoBlocks, YaoArrayRegister
    using YaoBlocks
    using YaoArrayRegister
end
```

# [Quantum Registers](@id registers)

A quantum register is a quantum state or a batch of quantum states.
`Yao` provides two types of quantum registers [`ArrayReg`](@ref) and [`BatchedArrayReg`](@ref).

```@docs
AbstractRegister
AbstractArrayReg
ArrayReg
BatchedArrayReg
```

We define some shortcuts to create simulated quantum states easier:

```@docs
arrayreg
product_state
zero_state
zero_state_like
rand_state
uniform_state
ghz_state
clone
```

In a register, qubits are distinguished as active and inactive (or remaining).
The total number of qubits is the number of active qubits plus the number of remaining qubits. 
Only active qubits are visible to quantum operators and the number of these qubits are the *size* of a register.
Making this distinction of qubits allows writing reusable quantum circuits.
For example, Suppose we want to run a quantum Fourier transformation circuit of size 4 on qubits `(1, 3, 5, 7)`,
we first set the target qubits to active qubits the reset to inactive, then we apply the circuit on it, finally we unset the inactive qubits.

```@docs
nqudits
nqubits
nactive
nremain
nbatch,
nlevel,
focus!
focus
relax!
zero_state
exchange_sysenv
```

## Storage

Both [`ArayReg`](@reef) and [`BatchedArrayReg`](@ref) use matrices as the storage. For example, for a quantum register with ``a`` active qubits, ``r`` remaining qubits and batch size ``b``, the storage is as follows

![](../assets/images/regstorage.svg)

The first dimension of size ``2^a`` is for active qubits, only this subset of qubits are allowed to interact with blocks. Since we reshaped the state vector into a matrix, applying a quantum operator can always be represented as a matrix-matrix multiplication . In practice, most gates have in-place implementation that does not require constructing the operator matrix explicitly.

You can access different views of the storage of an [`ArrayReg`](@ref) with the following functions:

```@docs
state
basis
statevec
relaxedvec
hypercubic
rank3
viewbatch
transpose_storage
```

## Operations

The list of arithmetic operations for [`ArrayReg`](@ref) include 
* `+`
* `-`
* `*`
* `/` (scalar)
* `adjoint`

Then the inner product can be computed as follows.

```julia
julia> reg = rand_state(3);

julia> reg' * reg
0.9999999999999998 + 0.0im
```

```@docs
AdjointArrayReg
```

We also have some faster inplace versions of arithematic operations
```@docs
regadd!,
regsub!,
regscale!,
```

We also define the following functions for state normalization, and distance measurement.
```@docs
normalize!
isnormalized
fidelity
tracedist
```

## Resource management and addressing

```@docs
add_qudits!
add_qubits!
append_qudits!
append_qubits!
reorder!
invorder!
```

Only a subset of qubits that does not interact with other qubits can be removed, the best approach is first measuring it in computational basis first.
It can be done with the [`measure!`](@ref) function by setting the first argument to `RemoveMeasured()`.

## Instruction set

Although we have matrix representation for Yao blocks, specialized instructions are much faster and memory efficient than using the matrix-matrix product.
These instructions are specified with the `instruct!` function listed bellow.

```@docs
YaoArrayRegister.instruct!
```

## Measurement

We have a true measure function `measure!` that collapses the state after the measurement.
We also have some "cheating" functions to facilitate classical simulation.

```@docs
measure!
measure
select!
select
collapseto!
probs
most_probable,
```

## Density matrices

```@docs
DensityMatrix
density_matrix
partial_tr
purify
von_neumann_entropy,
mutual_information,
```
