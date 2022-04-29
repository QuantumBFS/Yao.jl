# Performance Tips

## Use the correct block types

### `put` v.s. `subroutine`
While both blocks maps a subblock to a subset of qudits, their implementations are purposes are quite different.
The [`put`](@ref) block applies the gate in a in-place manner, which requires the static matrix representation of its subblock.
It works the best when the subblock is small.

The [`subroutine`](@ref) block is for running a sub-program in a subset of qubits. It first sets target qubits as active qubits using the [`focus!`](@ref) function,
then apply the gates on active qubits. Finally, it unsets the active qubits with the [`relax!`](@ref) function.

```julia
julia> using Yao

julia> reg = rand_state(20);

julia> @time apply(reg, put(20, 1:6=>EasyBuild.qft_circuit(6)));  # second run
  0.070245 seconds (1.32 k allocations: 16.525 MiB)

julia> @time apply(reg, subroutine(20, EasyBuild.qft_circuit(6), 1:6));  # second run
  0.036840 seconds (1.07 k allocations: 16.072 MiB)
```

### `repeat` v.s. `put`
[`repeat`](@ref) block is not only an alias of a chain of put, sometimes it can provide speed ups due to the different implementations.

```julia
julia> reg = rand_state(20);

julia> @time apply!(reg, repeat(20, X));
  0.002252 seconds (5 allocations: 656 bytes)

julia> @time apply!(reg, chain([put(20, i=>X) for i=1:20]));
  0.049362 seconds (82.48 k allocations: 4.694 MiB, 47.11% compilation time)
```

Other gates accelerated by `repeat` include: `X`, `Y`, `Z`, `S`, `T`, `Sdag`, and `Tdag`.

### Diagonal matrix in `time_evole`

## Register storage
One can use transposed storage and normal storage for computing batched registers.
The transposed storage is used by default because it is often faster in practice.
One can use [`transpose_storage`](@ref) to convert the storage.

## Multithreading
Multithreading can be switched on by starting Julia in with a global environment variable `JULIA_NUM_THREAD`
```bash
$ JULIA_NUM_THREAD=4 julia xxx.jl
```
Check the [Julia Multi-Treading manual](https://docs.julialang.org/en/v1/manual/multi-threading/) for details.

## GPU backend
The GPU backend is supported in [`CuYao`](https://github.com/QuantumBFS/CuYao.jl).

```julia
julia> using Yao, CuYao

julia> reg = CuYao.cu(rand_state(20));

julia> circ = Yao.EasyBuild.qft_circuit(20);

julia> apply!(reg, circ)
ArrayReg{2, ComplexF64, CuArray...}
    active qubits: 20/20
    nlevel: 2
```