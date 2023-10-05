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
function contract(c::TensorNetwork)
    return c.code(c.tensors...; size_info=uniformsize(c.code, 2))
end
function OMEinsum.optimize_code(c::TensorNetwork, args...)
    optcode = optimize_code(c.code, uniformsize(c.code, 2), args...)
    return TensorNetwork(optcode, c.tensors)
end
function OMEinsum.contraction_complexity(c::TensorNetwork)
    return contraction_complexity(c.code, uniformsize(c.code, 2))
end