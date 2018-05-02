# Design Notes

## Quantum Register

Quantum Register is the abstraction of a quantum states being processed by a circuit.

```julia
mutable struct Register{T <: AbstractArray, N} <: AbstractRegister
    data::T
end
```

the register's data's shape can be permuted and reshaped, but it cannot be shrinked, the total size will be kept to

```math
2^N
```

## Block

**Block**s are the basic component of an quantum oracle in **QuCircuit.jl**.

### Memory Contiguous

Block should be contiguous on quantum registers, which means a block for N-qubits starts from location k, should be contiguous on this quantum memory and thus will be contiguous on its classical simulated quantum register too.

```
-- [ ] -- [ ] --
```

### Packer

A **Packer** is an special block that will permute the order of quantum memory address. This will make in-contiguous memory address become contiguous and the quantum state will be reshape to a matrix that has the related shape to the operator. But in simulation, this will cause an extra memory allocation.

```
 *****         *****         ****
 *   * -- 1    *   * -- 1 -- ****
 *   * -- 2    *   * -- 3 -- ****
 *   * -- 3 => *   * -- 5 -- ****
 *   * -- 4    *   * -- 2    ****
 *   * -- 5    *   * -- 4
 *****         *****
```

However, by default, the block tree will not help in organizing the order of memory address.

### Default Behaviour of Block Evaluation

The default behaviour of the evaluation of a block tree will use kronecker product to assemble different gates, e.g, the following circuit will be evaluated by

```

-- [Z] ---------

-- [X] -- [X] --

---------- X ---
           |
--------- [ ] --

```

By default, its evaluation is equivalent to

```math
Z \otimes X \otimes CNOT \cdot I \otimes X \otimes I \otimes I
```

This is because the gates are stored by a tree inside a block with their memory address and the calculation order on each line, by default the order will be the insertion order.

```
       gates address  order
---------------------------
Block: Z     (1, )      1
       X     (2, )      1
       X     (2, )      2
       CNOT  (3, 4)     1
```

The `apply!` method will first run through the memory address `1:N` (N = 4 here) to calculate gates with same order on each line (if there is no gate, then use an identity) until it meets the maximum depth of the block, the maximum depth will be the maximum order.

User can specify the calculation order by input an integer, and when

```
        gates address order
----------------------------
Block:  Z     (1, )      1
        X     (2, )      1
        X     (2, )      2
        CNOT  (3, 4)     2
```

the calculation will be equivalent to

```math
Z \otimes X \otimes I \otimes I \cdot I \otimes X \otimes CNOT
```

### More efficient controlled gates

By default, some commonly used controlled gates like CNOT will be converted to a matrix and evaluate with other gates together, however, controlled gates can be an arbitrary gate with an identity in a block matrix, and can be derived

```math
COP = \begin{pmatrix}
 I & 0\\
 0 & X\\
\end{pmatrix} 
```

```math
\begin{aligned}
COP |c\rangle|\Psi\rangle &= (\alpha_1|0\rangle + \alpha_2|1\rangle) X|\Psi\rangle\\
                          &= \alpha_1|0\rangle|\Psi\rangle + \alpha_2|1\rangle X |\Psi\rangle
\end{aligned}
```

Therefore, the functionality of a controlled gate will looks like

```math
\begin{aligned}
& U_1(\eta_1)\cdot COP(c, \Psi) \cdot U_2(\eta_2) \cdot U_3(\eta_3)|\eta_1\rangle|c\rangle|\eta_2\rangle|\Psi\rangle|\eta_3\rangle\\
& \rightarrow U_1(\eta_1)\cdot COP(c, \Psi) \cdot U_2(\eta_2) \cdot U_3(\eta_3) |\eta_1\rangle (\alpha_1|0\rangle + \alpha_2|1\rangle) |\eta_2\rangle |\Psi\rangle |\eta_3\rangle\\
& \rightarrow \alpha_1 U_1\otimes I \otimes U_2 \otimes I \otimes U_3|\eta_1\rangle |0\rangle |\eta_2\rangle |\Psi\rangle |\eta_3\rangle + \alpha_2 U_1\otimes I \otimes U_2 \otimes X \otimes U_3 |\eta\rangle |1\rangle |\eta_2\rangle |\Psi\rangle |\eta_3\rangle\\
& \rightarrow U_1\otimes I \otimes U_2 \otimes I \otimes U_3 |\phi\rangle + \alpha_2 U_1\otimes I\otimes U_2 \otimes (X - I) \otimes U_3 |\eta_1\rangle |1\rangle |\eta_2\rangle |\Psi\rangle |\eta_3\rangle
\end{aligned}
```
