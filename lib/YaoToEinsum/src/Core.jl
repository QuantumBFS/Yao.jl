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
    optimize_code(c::TensorNetwork, optimizer=TreeSA())

Optimize the code of the tensor network.

### Arguments
* `c::TensorNetwork`: The tensor network.
* `optimizer::Optimizer`: The optimizer to use, default is `TreeSA()`. Please check [OMEinsumContractors.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl) for more information.
"""
function OMEinsum.optimize_code(c::TensorNetwork, args...; size_info=uniformsize(c.code, 2))
    optcode = optimize_code(c.code, size_info, args...)
    return TensorNetwork(optcode, c.tensors)
end

"""
    contraction_complexity(c::TensorNetwork)

Return the contraction complexity of the tensor network.
"""
function OMEinsum.contraction_complexity(c::TensorNetwork; size_info=uniformsize(c.code, 2))
    return contraction_complexity(c.code, size_info)
end