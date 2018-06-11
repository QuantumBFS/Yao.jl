# Block Operations

## Direct Construction of sparse gates

For example, constructing `X(2, 4)`, we can change bases like

1. old basis \(0, 1, ..., 15\),
2. old bitstring basis \(0000, 0001, ..., 1111\),
3. new bitstring basis \(0100, 0101, ..., 1011\),
4. new basis \(4, 5, ..., 11\).

Progamming way in julia to obtain new basis is
```julia
basis = collect(0:1<<4-1)
basis $= 1 << 2  # for newer julia, $ will be deprecated, no-ascii \xor can be used.
```
Which is equivalent to a `Permutation` matrix or a more general `PermutationMultiply` matrix.
