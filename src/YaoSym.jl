module YaoSym

# load simplify
include("../simplify/src/Simplify.jl")
include("engine/engine.jl")

include("register.jl")
include("blocks.jl")

using Requires

@init @require SymEngine="123dc426-2d89-5057-bbad-38513e3affd8" begin
    include("symengine/backend.jl")
end

end # module
