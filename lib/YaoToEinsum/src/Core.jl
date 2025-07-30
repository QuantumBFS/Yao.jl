abstract type AbstractMappingMode end
struct DensityMatrixMode <: AbstractMappingMode end
struct PauliBasisMode <: AbstractMappingMode end
struct VectorMode <: AbstractMappingMode end

"""
    TensorNetwork

A (generalized) tensor network representation of a quantum circuit.

### Fields
* `code::AbstractEinsum`: The einsum code.
* `tensors::Vector`: The tensors in the network.
"""
struct TensorNetwork
    code::AbstractEinsum
    tensors::Vector
end
function Base.show(io::IO, c::TensorNetwork)
    print(io, "TensorNetwork")
    print(io, "\n")
    print(io, contraction_complexity(c))
end
function Base.show(io::IO, ::MIME"text/plain", c::TensorNetwork)
    Base.show(io, c)
end
function Base.iterate(c::TensorNetwork, state=1)
    if state > 2
        return nothing
    elseif state == 1
        return (c.code, 2)
    else
        return (c.tensors, 3)
    end
end

"""
    contract(c::TensorNetwork)

Contract the tensor network, and return the result tensor.
"""
function contract(c::TensorNetwork)
    return c.code(c.tensors...)
end

"""
    optimize_code(c::TensorNetwork, optimizer=TreeSA(); slicer=nothing)

Optimize the code of the tensor network.

### Arguments
- `c::TensorNetwork`: The tensor network.
- `optimizer::Optimizer`: The optimizer to use, default is `OMEinsum.TreeSA()`.

### Keyword Arguments
- `slicer`: The slicer to use, default is `nothing`. It can be e.g. `OMEinsum.TreeSASlicer(score=OMEinsum.ScoreFunction(sc_target=30))`.

For more, please check [OMEinsumContractionOrders documentation](https://tensorbfs.github.io/OMEinsumContractionOrders.jl/dev/).
"""
function OMEinsum.optimize_code(c::TensorNetwork, args...; kwargs...)
    size_info = OMEinsum.get_size_dict(getixsv(c.code), c.tensors)
    optcode = optimize_code(c.code, size_info, args...; kwargs...)
    return TensorNetwork(optcode, c.tensors)
end

"""
    contraction_complexity(c::TensorNetwork)

Return the contraction complexity of the tensor network.
"""
function OMEinsum.contraction_complexity(c::TensorNetwork)
    size_info = OMEinsum.get_size_dict(getixsv(c.code), c.tensors)
    return contraction_complexity(c.code, size_info)
end
