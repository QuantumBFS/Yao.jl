module YaoToEinsumCUDAExt
using CUDA, YaoToEinsum

export cu

function cu(tnet::TensorNetwork)
    return TensorNetwork(tnet.code, tnet.tensors .|> CuArray)
end
end