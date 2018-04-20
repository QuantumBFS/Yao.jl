# Requirements for Differenciable Circuit
## Wave Function
A wave function is a tensor of order-3, psi(f, r, b).

* f: focused dimensions
* r: remaining dimensions
* b: batch dimension.

##### State manipulation
* `psi = Psi(psi1, '0', psi2, '0x4', ...)`: merge disentangled spaces `psi1`, `0`, `psi2`, `0000` et. al. to create a new larger space.
* `psi = focus(psi, [1, 3, 2])`: change the operation space to [1, 3, 2], now psi is a tensor of shape (2^3, 2^(num_bit-3), b).
this is achieved by index unraveling and permuting. `Focus()` is equivalent to making all qubits focused.
* `rho = density_matrix(psi)`: get the reduced density matrix for currently focused space.
* `psi = safe_remove(psi, [2, 3])`: remove disentangled qubits `[2, 3]` from system safely (will check whether this qubit is entangled with other parts).
maybe `measure_and_remove` can be a better design and is often what needed.

All operations must be applied on the first (focused) dimension of `psi`.

##### Notes:
Here, benchmark is needed to optimize the memory structure.

## Operations
Illustration of block-focus scheme
![block-focus illustration](images/blockfocus.png)

* Gate
    * define: low dimensional building material of circuits.
* Operation
    * define: operations changes a state
    * use: `apply(operation, operation parameters, wave function)`
    * e.g. Measure, Focus, Block
* Block <: Operation
    * define: blocks are square linear operators (i.e. with `mv` method, and does not change size of a vector). It takes `Block-List` as its member, thus can be viewed as a tree.
    * e.g. RotationBlock, Entangler, ElementaryBlock
* ElementaryBlock <: Block
    * define: blocks having no child, it does not support slicing.
    * e.g. Grover search, GateBlock
* GateBlock <: ElementaryBlock
    * define: gate-blocks are special blocks that can be defined as `GateBlock(gate, list of sites, number of qubits)`.
    * e.g. X, CNOT

##### Notes:
* The operation space of a block is all focused qubits, which means specifying its position is not needed. To set operating qubits, one should use `Focus(...)` object.

## Parameter dispatch and cache
Cache is used for storing intermediate variables to speed up calculation.

```python
if (cache is favored and block is cached) and (parameters == cached parameters):
    apply(cached linear operator, psi)
else:
    if cache is favored:
        calculate sparse_matrix
        cache!(block, parameters, sparse_matrix)
        apply sparse matrix to psi
    else:
        if block has children:
            dispatch paramters to children
        else:
            apply(block, parameters, psi)
```

A block has its favored data format, such as 'sparse', 'function' and 'mpo', only `sparse` and `mpo` allow caching.
Caching is needed only if this matrix can be used multiple times.

e.g. a block consist of a queue of Controlled-Z gates, the sparse matrix representation is diagonal, caching the constructed sparse matrix can be super efficient for future use.

