module YaoSym

using Requires

include("register.jl")

function __init__()
    @require SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8" include("symengine/backend.jl")
end

end # module
