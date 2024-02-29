```@meta
CurrentModule = Yao
```

# CUDA extension - CuYao

## Tutorial
`CuYao` is a CUDA extension of Yao, which allows you to run Yao circuits on GPU. The usage of `CuYao` is similar to `Yao`, but with some extra APIs to upload and download registers between CPU and GPU:
- `cu(reg)` to upload a registe `reg` to GPU, and
- `cpu(cureg)` to download a register `cureg` from GPU to CPU.

```julia
julia> using Yao, CUDA

# create a register on GPU
julia> cureg = rand_state(9; nbatch=1000) |> cu;   # or `curand_state(9; nbatch=1000)`.

# run a circuit on GPU
julia> cureg |> put(9, 2=>Z);

# measure the register on GPU
julia> measure!(cureg)
1000-element CuArray{DitStr{2, 9, Int64}, 1, CUDA.Mem.DeviceBuffer}:
 110110100 ₍₂₎
 000100001 ₍₂₎
 111111001 ₍₂₎
             ⋮
 010001101 ₍₂₎
 000100110 ₍₂₎

# download the register to CPU
julia> reg = cureg |> cpu;
```


## Features
Supported gates:

- general U(N) gate
- general U(1) gate
- X, Y, Z gate
- T, S gate
- SWAP gate
- control gates

Supported register operations:

- measure!, measure_reset!, measure_remove!, select
- append_qudits!, append_qubits!
- insert_qudit!, insert_qubits!
- focus!, relax!
- join
- density_matrix
- fidelity
- expect

Autodiff:
- autodiff is supported when the only parameterized gates are rotation gates in a circuit.

## API
```@docs
cpu
curand_state
cuzero_state
cuproduct_state
cuuniform_state
cughz_state
```

!!! note
    the `cu` function is not documented in this module, but it is used to upload a register to GPU.