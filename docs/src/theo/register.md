# Register

## Storage

#### LDT format
Concepturely, a wave function ``|\psi\rangle`` can be represented in a low dimentional tensor (LDT) format of order-3, L(f, r, b).

* f: focused (i.e. operational) dimensions
* r: remaining dimensions
* b: batch dimension.

For simplicity, let's ignore batch dimension for the momentum, we have
```math
|\psi\rangle = \sum\limits_{x,y} L(x, y, .) |j\rangle|i\rangle
```

Given a configuration `x` (in operational space), we want get the i-th bit using `(x<<i) & 0x1`, which means putting the small end the qubit with smaller index. In this representation `L(x)` will get return ``\langle x|\psi\rangle``.

!!! note

    **Why not the other convension**: Using the convention of putting 1st bit on the big end will need to know the total number of qubits `n` in order to know such positional information.

#### HDT format
Julia storage is column major, if we reshape the wave function to a shape of ``2\times2\times ... \times2`` and get the HDT (high dimensional tensor) format representation H, we can use H(``x_1, x_2, ..., x_3``) to get ``\langle x|\psi\rangle``.

## Operations
#### Kronecker product of operators
In order to put small bits on little end, the Kronecker product is ``O = o_n \otimes \ldots \otimes o_2 \otimes o_1`` where the subscripts are qubit indices.
#### Measurements
Measure means `sample` and `projection`.

##### Sample
Suppose we want to measure operational subspace, we can first get
```math
p(x) = \|\langle x|\psi\rangle\|^2 = \sum\limits_{y} \|L(x, y, .)\|^2.
```
Then we sample an ``a\sim p(x)``. If we just sample and don't really measure (change wave function), its over.

##### Projection
```math
|\psi\rangle' = \sum_y L(a, y, .)/\sqrt{p(a)} |a\rangle |y\rangle
```

Good! then we can just remove the operational qubit space since `x` and `y` spaces are totally decoupled and `x` is known as in state `a`, then we get
```math
|\psi\rangle'_r = \sum_y l(0, y, .) |y\rangle
```
where `l = L(a:a, :, :)/sqrt(p(a))`.
