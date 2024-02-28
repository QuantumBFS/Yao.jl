"""
Extensible Framework for Quantum Algorithm Design for Humans.
"""
module Yao

export 幺

"""
Extensible Framework for Quantum Algorithm Design for Humans.

简单易用可扩展的量子算法设计框架。

幺 means normalized but not orthogonal in Chinese.
"""
const 幺 = Yao

using Reexport
@reexport using YaoArrayRegister, YaoBlocks, YaoSym, YaoPlots
using YaoArrayRegister.BitBasis, YaoAPI

using YaoBlocks:
    color,
    PropertyTrait,
    render_params,
    print_annotation,
    print_prefix,
    print_title,
    print_block

export EasyBuild
# CUDA APIs
export cpu, cuzero_state, cuuniform_state, curand_state, cuproduct_state, cughz_state

include("cudainterfaces.jl")
include("EasyBuild/easybuild.jl")
include("deprecations.jl")

end # module
