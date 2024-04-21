module YaoToEinsumCUDAExt
using CUDA, YaoToEinsum

function CUDA.cu(tnet::TensorNetwork)
    return TensorNetwork(tnet.code, tnet.tensors .|> CuArray)
end
end
