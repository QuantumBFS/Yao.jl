# Cache

## Key-value Storage

Like PyTorch, MXNet, we use a key value storage (a cache pool, like dmlc/ps-lite) to store cached blocks. Cached blocks are frequently used blocks with specific matrix form. You can choose which type of matrix storage to store in a cache pool.

The benefit of this solution includes:

- more contiguous memory address (compare to previous plans, e.g `CacheBlock`, block with a cache dict)
- more convenient for traversing cached parameters
- this solution offer us flexibility for future implementation on GPUs and large clusters.

## Julia's Dict

```julia
Base.hashindex(key, sz)
```

`sz` is the total length of the list of slots.

*TO BE DONE...*

## Implementation

Unlike parameter servers in deep learning frameworks.
Our cache server contains not only the cached (sparse) matrix,
but also its related cache level,
which defines its update priority during the evluation of a quantum circuit.
Or it can be viewed as a parameter server that stores a `CacheElement`).

### Solutions

*TO BE DONE...*
