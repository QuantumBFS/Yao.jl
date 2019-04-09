```@meta
CurrentModule = YaoArrayRegister
```

# Array Registers

We provide [`ArrayReg`](@ref) as built in register type for simulations. It is a simple wrapper of a Julia array, e.g on CPU, we use `Array` by default and on CUDA devices we could use `CuArray`. You don't have to define your custom array type if the storage is array based.

## Constructors

```@docs
ArrayReg
```

We define some shortcuts to create simulated quantum states easier:

```@docs
product_state
zero_state
rand_state
uniform_state
oneto
repeat
```

## Properties

You can access the storage of an [`ArrayReg`](@ref) with:

```@docs
state
statevec
relaxedvec
hypercubic
rank3
```

## Operations

We defined basic arithmatics for [`ArrayReg`](@ref), besides since we do not garantee
normalization for some operations on [`ArrayReg`](@ref) for simulation, [`normalize!`](@ref) and 
[`isnormalized`](@ref) is provided to check and normalize the simulated register.

```@docs
normalize!
isnormalized
```

## Specialized Instructions

We define some specialized instruction by specializing [`instruct!`](@ref) to improve the performance for simulation and dispatch them with multiple dispatch.

Implemented `instruct!` is listed below:

```@eval
using YaoArrayRegister, Latexify

## get the method table first
mtable = methods(instruct!)
## preprocess the method table, filter out what's in YaoArrayRegister

get_storage_sig(x) = get_storage_sig(x, 2)
get_storage_sig(x::Method, k) = get_storage_sig(x.sig, k)
get_storage_sig(x, k) = x.parameters[k]
get_storage_sig(x::UnionAll, k) = get_storage_sig(x.body, k)

list = filter(x->get_storage_sig(x) <: AbstractVecOrMat, mtable.ms)
list = filter(x->x.module === YaoArrayRegister, list)

registers = map(list) do x
    sig = get_storage_sig(x)
    sig <: AbstractVecOrMat ? "AbstractVecOrMat" :
    sig <: Array ? "Array" : string(sig)
end

operators = map(list) do x
    sig = get_storage_sig(x, 3)
    sig <: AbstractMatrix ? string(sig) :
    sig <: Val ? string(sig.parameters[1]) :
    string(sig)
end

nqubits_str = map(list) do x
    sig = get_storage_sig(x, 4)
    sig <: Union{Int, Tuple{Int}} ? "single" :
    sig <: NTuple{N, Int} where N ? "multiple" : error("instruct is not specialized correctly, got $sig")
end

control_str = map(list) do x
    try
        sig = get_storage_sig(x, 5)
        sig <: Union{Int, Tuple{Int}} ? "single" :
        sig <: NTuple{N, Int} where N ? "multiple" : error("instruct is not specialized correctly, got $sig")
    catch e
        if e isa BoundsError
            return "none"
        end
    end
end

function make_table(registers, operators, nqubits, controls)
    N = length(registers)
    out = Dict("registers"=>[], "operators"=>[], "nqubits"=>[], "controls"=>[])

    count = 0; k = 1; searched = []
    while count != N
        if k in searched
            k = k + 1
            continue
        else
            indices = findall(x->x==operators[k], operators)
            append!(searched, indices)
        end

        push!(out["operators"], operators[k])
        push!(out["registers"], join(unique(registers[indices]), ", "))
        push!(out["nqubits"], join(unique(nqubits[indices]), ", "))
        push!(out["controls"], join(unique(controls[indices]), ", "))
        count += length(indices)
        k += 1
    end
    return out
end

d = make_table(registers, operators, nqubits_str, control_str)
data = hcat(map(x->"`$x`", d["registers"]), map(x->"`$x`", d["operators"]), d["nqubits"], d["controls"])
mdtable(data; latex=false, head=["registers", "operators", "nqubits", "controls"])
```

## Measurement

Simulation of measurement is mainly achieved by sampling and projection.

#### Sample

Suppose we want to measure operational subspace, we can first get
```math
p(x) = \|\langle x|\psi\rangle\|^2 = \sum\limits_{y} \|L(x, y, .)\|^2.
```
Then we sample an ``a\sim p(x)``. If we just sample and don't really measure (change wave function), its over.

#### Projection
```math
|\psi\rangle' = \sum_y L(a, y, .)/\sqrt{p(a)} |a\rangle |y\rangle
```

Good! then we can just remove the operational qubit space since `x` and `y` spaces are totally decoupled and `x` is known as in state `a`, then we get

```math
|\psi\rangle'_r = \sum_y l(0, y, .) |y\rangle
```

where `l = L(a:a, :, :)/sqrt(p(a))`.


## Others

```@autodocs
Modules = [YaoArrayRegister]
Order = [:function]
```
