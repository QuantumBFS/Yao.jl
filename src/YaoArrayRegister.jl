"""
YaoArrayRegister.jl is a component package in the [Yao.jl](https://github.com/QuantumBFS/Yao.jl) ecosystem.
It provides the most basic functionality for quantum
computation simulation in Julia and a quantum register type `ArrayReg`. You will be
able to simulate a quantum circuit alone with this package in principle.
"""
module YaoArrayRegister

include("utils.jl")
include("register.jl")
include("operations.jl")
include("focus.jl")

include("instruct.jl")

include("density_matrix.jl")
include("measure.jl")

include("deprecations.jl")

end # module
