# Yao v0.4.0

## More Modulized Arch

We make Yao a meta package over several component packages to make it more modulized to make the development faster.
Now most of the code are in

- YaoBase
- YaoBlocks
- YaoArrayRegister

## Block Tree

Now all the blocks in Yao represents a quantum operator and there's no `MatrixBlock` anymore,
most blocks will have `mat` to get its matrix, but blocks might not have matrix or hard to have
a matrix will just error when you try to call it.

There's no need to insert classical function inside blocks with `FunctionBlock` instead of just doing
a function call.

Therefore, the following types are removed:

```julia
FunctionBlock
MatrixBlock
```

## Registers

Since we are going to support more kinds of registers, `register` is deprecated, and use the type
constructor directly is preferred, e.g `ArrayReg`.

## Circuit Simplification

We add basic support on circuit simplification, and provide an extensible interface to add new simplification rules. A single new interfce: `simplify` is added.
