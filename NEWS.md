# Yao.jl v0.3.0 Release Notes
* Intrinsic parameters interfaces `iparameters` (return tuple), `setiparameters!` and `niparameters`.

## Renaming
* blocks -> subblocks, which will return tuple if the block is not mutable, otherwise a vector (e.g. composite blocks like `ChainBlock`).
