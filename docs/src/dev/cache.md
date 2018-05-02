# Cache

## Key-value Storage

Like PyTorch, MXNet, we use a key value storage (a cache pool) to store cached blocks. Cached blocks are frequently used blocks with specific matrix form. You can choose which type of matrix storage to store in a cache pool.

The benefit of this solution includes:

- more contiguous memory address (compare to previous plans, e.g `CacheBlock`, block with a cache dict)
- more convenient for traversing cached parameters
