# How to overload exist method for a block

every block has two method: `mat` & `apply!`, overload `mat` to define how to gather this block's matrix
form, overload `apply!` to define how to apply this block to a register.

Prototypes:

```julia
apply!(reg, block)
mat(block)
```
