# Yao.jl v0.3.0 Release Notes
`measure!` and `measure_and_remove!` now returns measure results only.
## Renaming
* blocks -> subblocks, which will return tuple if the block is not mutable, otherwise a vector (e.g. composite blocks like `ChainBlock`).

## Deprecation
* `hasparameters` is deprecated, use `iparameters(blk) > 0` (for intrinsic) or `nparameters(blk) > 0` instead.
* Intrinsic parameters interfaces `iparameters` (return tuple), `setiparameters!` and `niparameters`.

