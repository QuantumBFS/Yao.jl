```@meta
CurrentModule = YaoArrayRegister
DocTestSetup = quote
    using Yao
    using BitBasis
    using YaoAPI
    using YaoBlocks
    using YaoArrayRegister
end
```

# [Quantum Registers](@id registers)

## Constructing quantum states

A quantum register is a quantum state or a batch of quantum states.
Qubits in a Yao register can be active or inactive.
Only active qubits are visible to quantum operators, which enables applying quantum operators on a subset of qubits.
For example, Suppose we want to run a quantum Fourier transformation circuit of size 4 on qubits `(1, 3, 5, 7)` with the [`focus!`](@ref) function,
we first set these qubits to active qubits the rest to inactive, then we apply the circuit on the active qubits, and finally we switch back to the original configuration with the [`relax!`](@ref) function.

`Yao` provides two types of quantum registers [`ArrayReg`](@ref) and [`BatchedArrayReg`](@ref). Both use matrices as the storage. 
For example, for a quantum register with ``a`` active qubits, ``r`` remaining qubits and batch size ``b``, the storage is as follows.

![](../assets/images/regstorage.svg)

The first dimension of size ``2^a`` is for active qubits, only this subset of qubits are allowed to interact with quantum operators. Since we reshaped the state vector into a matrix, applying a quantum operator can be conceptually represented as a matrix-matrix multiplication.

Various quantum states can be created with the following functions.
```@repl register
using Yao
reg = ArrayReg([0, 1, -1+0.0im, 0])  # a unnormalized Bell state |01⟩ - |10⟩
statevec(reg)  # a quantum state is represented as a vector
print_table(reg)
```

```@repl register
reg_zero = zero_state(3)  # create a zero state |000⟩
print_table(reg_zero)
```

```@repl register
reg_rand = rand_state(ComplexF32, 3)  # a random state
```

```@repl register
reg_uniform = uniform_state(ComplexF32, 3)  # a uniform state
print_table(reg_uniform)
```

```@repl register
reg_prod = product_state(bit"110")  # a product state
bit"110"[3]  # the bit string is in little-endian format
print_table(reg_prod)
```

```@repl register
reg_ghz = ghz_state(3)  # a GHZ state
print_table(reg_ghz)
von_neumann_entropy(reg_ghz, (1, 3)) / log(2) # entanglement entropy between qubits (1, 3) and (2,)
```

```@repl register
reg_rand3 = rand_state(3, nlevel=3)  # a random qutrit state
reg_prod3 = product_state(dit"120;3")  # a qudit product state, what follows ";" symbol denotes the number of levels
print_table(reg_prod3)
```

```@repl register
reg_batch = rand_state(3; nbatch=2)  # a batch of 2 random qubit states
print_table(reg_batch)
reg_view = viewbatch(reg_batch, 1)  # view the first state in the batch
print_table(reg_view)
```

```@repl register
reg = rand_state(3; nlevel=4, nbatch=2)
nqudits(reg)  # the total number of qudits
nactive(reg)  # the number of active qubits
nremain(reg)  # the number of remaining qubits
nbatch(reg)  # the batch size
nlevel(reg)  # the number of levels of each qudit
basis(reg)  # the basis of the register
focus!(reg, 1:2)  # set on the first two qubits as active
nactive(reg)  # the number of active qubits
basis(reg)  # the basis of the register
relax!(reg)  # set all qubits as active
nactive(reg)  # the number of active qubits
reorder!(reg, (3,1,2))  # reorder the qubits

reg1 = product_state(bit"111");
reg2 = ghz_state(3);
fidelity(reg1, reg2)  # the fidelity between two states
tracedist(reg1, reg2)  # the trace distance between two states
```

## Arithmetic operations

The list of arithmetic operations for [`ArrayReg`](@ref) include 
* `+`
* `-`
* `*`
* `/` (scalar)
* `adjoint`


```@repl register
reg1 = rand_state(3)
reg2 = rand_state(3)
reg3 = reg1 + reg2  # addition
normalize!(reg3)  # normalize the state
isnormalized(reg3)  # check if the state is normalized
reg1 - reg2  # subtraction
reg1 * 2  # scalar multiplication
reg1 / 2  # scalar division
reg1'  # adjoint
reg1' * reg1  # inner product
```

## Register operations
```@repl register
reg0 = rand_state(3)
append_qudits!(reg0, 2)  # append 2 qubits
insert_qudits!(reg0, 2, 2)  # insert 2 qubits at the 2nd position
```

Comparing with using matrix multiplication for quantum simulation, using specialized instructions are much faster and memory efficient. These instructions are specified with the [`instruct!`](@ref) function.

```@repl register
reg = zero_state(2)
instruct!(reg, Val(:H), (1,))  # apply a Hadamard gate on the first qubit
print_table(reg)
```

## Measurement

We use the [`measure!`](@ref) function returns the measurement outcome and collapses the state after the measurement.
We also have some "cheating" version [`measure`](@ref) that does not collapse states to facilitate classical simulation.

```@repl register
measure!(reg0, 1)  # measure the qubit, the state collapses
measure!(reg0)  # measure all qubits
measure(reg0, 3)  # measure the qubit 3 times, the state does not collapse (hacky)
reorder!(reg0, 7:-1:1)  # reorder the qubits
measure!(reg0)
invorder!(reg0)  # reverse the order of qubits
measure!(reg0)
measure!(RemoveMeasured(), reg0, 2:4)  # remove the measured qubits
reg0

reg1 = ghz_state(3)
select!(reg1, bit"111")  # post-select the |111⟩ state
isnormalized(reg1)  # check if the state is normalized
```

## Density matrices

```@repl register
reg = rand_state(3)
rho = density_matrix(reg)  # the density matrix of the state
rand_density_matrix(3)  # a random density matrix
completely_mixed_state(3)  # a completely mixed state
partial_tr(rho, 1)  # partial trace on the first qubit
purify(rho)  # purify the state
von_neumann_entropy(rho)  # von Neumann entropy
mutual_information(rho, 1, 2)  # mutual information between qubits 1 and 2
```

## API
The constructors and functions for quantum registers are listed below.
```@docs
AbstractRegister
AbstractArrayReg
ArrayReg
BatchedArrayReg
```

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

The following functions are for querying the properties of a quantum register.

```@docs
nqudits
nqubits
nactive
nremain
nbatch
nlevel
focus!
focus
relax!
exchange_sysenv
```

The following functions are for querying the state of a quantum register.

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

The following functions are for arithmetic operations on quantum registers.

```@docs
AdjointArrayReg
```

We also have some faster inplace versions of arithematic operations
```@docs
regadd!
regsub!
regscale!
```

We also define the following functions for state normalization, and distance measurement.
```@docs
normalize!
isnormalized
fidelity
tracedist
```

The following functions are for adding and reordering qubits in a quantum register.

```@docs
insert_qudits!
insert_qubits!
append_qudits!
append_qubits!
reorder!
invorder!
```

The `instruct!` function is for applying quantum operators on a quantum register.

```@docs
YaoArrayRegister.instruct!
```

The following functions are for measurement and post-selection.

```@docs
measure!
measure
select!
select
collapseto!
probs
most_probable
```

The following functions are for density matrices.

```@docs
DensityMatrix
density_matrix
rand_density_matrix
completely_mixed_state
partial_tr
purify
von_neumann_entropy
mutual_information
```
