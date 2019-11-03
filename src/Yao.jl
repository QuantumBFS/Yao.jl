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
@reexport using YaoBase, YaoArrayRegister, YaoBlocks, YaoSym

include("deprecations.jl")

end # module
