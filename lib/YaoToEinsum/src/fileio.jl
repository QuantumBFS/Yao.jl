using JSON
using OMEinsum
using OMEinsum: NestedEinsum, SlicedEinsum

"""
    save_tensor_network(tn::TensorNetwork; folder::String)

Save a tensor network to a folder with separate files for code and tensors.
The code is saved using `OMEinsum.writejson` and tensors are saved as JSON.

# Arguments
- `tn::TensorNetwork`: The tensor network to save
- `folder::String`: The folder path to save the files

# Files Created
- `code.json`: Contains the einsum code using OMEinsum format
- `tensors.json`: Contains the tensor data as JSON

# Example
```julia
network = yao2einsum(circuit)
save_tensor_network(network; folder="my_network")
```
"""
function save_tensor_network(tn::TensorNetwork; folder::String)
    !isdir(folder) && mkpath(folder)

    # save code
    OMEinsum.writejson(joinpath(folder, "code.json"), tn.code)
    
    # save tensors
    open(joinpath(folder, "tensors.json"), "w") do io
        JSON.print(io, [tensor_to_dict(tensor) for tensor in tn.tensors], 2)
    end
    return nothing
end

"""
    load_tensor_network(folder::String)

Load a tensor network from a folder containing separate files for code and tensors.

# Arguments
- `folder::String`: The folder path containing the files

# Returns
- `TensorNetwork`: The loaded tensor network

# Required Files
- `code.json`: Contains the einsum code using OMEinsum format
- `tensors.json`: Contains the tensor data as JSON

# Example
```julia
network = load_tensor_network("my_network")
```
"""
function load_tensor_network(folder::String)
    !isdir(folder) && throw(SystemError("Folder not found: $folder"))
    
    code_path = joinpath(folder, "code.json")
    tensors_path = joinpath(folder, "tensors.json")
    !isfile(code_path) && throw(SystemError("Code file not found: $code_path"))
    !isfile(tensors_path) && throw(SystemError("Tensors file not found: $tensors_path"))
    
    code = OMEinsum.readjson(code_path)
    
    tensors = [tensor_from_dict(t) for t in JSON.parsefile(tensors_path)]
    return TensorNetwork(code, tensors)
end

"""
    tensor_to_dict(tensor::AbstractArray{T}) where T

Convert a tensor to a dictionary representation for JSON serialization.

# Arguments
- `tensor::AbstractArray{T}`: The tensor to convert

# Returns
- `Dict`: A dictionary containing tensor metadata and data

# Dictionary Structure
- `"size"`: The dimensions of the tensor
- `"complex"`: Boolean indicating if the tensor contains complex numbers
- `"data"`: The tensor data as a flat array of real numbers
"""
function tensor_to_dict(tensor::AbstractArray{T}) where T
    d = Dict()
    d["size"] = size(tensor)
    d["complex"] = T <: Complex
    d["data"] = reinterpret(real(T), vec(tensor))
    return d
end

"""
    tensor_from_dict(dict::Dict)

Convert a dictionary back to a tensor.

# Arguments
- `dict::Dict`: The dictionary representation of a tensor

# Returns
- `AbstractArray`: The reconstructed tensor

# Dictionary Structure Expected
- `"size"`: The dimensions of the tensor
- `"complex"`: Boolean indicating if the tensor contains complex numbers
- `"data"`: The tensor data as a flat array of real numbers
"""
function tensor_from_dict(dict::Dict)
    size_vec = dict["size"]
    is_complex = dict["complex"]
    data = collect(Float64, dict["data"])
    
    if is_complex
        complex_data = reinterpret(ComplexF64, data)
        return reshape(complex_data, size_vec...)
    else
        return reshape(data, size_vec...)
    end
end

