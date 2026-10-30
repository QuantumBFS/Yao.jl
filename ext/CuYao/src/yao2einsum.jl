function CUDA.cu(tnet::TensorNetwork)
    return TensorNetwork(tnet.code, tnet.tensors .|> CuArray, tnet.label_to_qubit)
end
