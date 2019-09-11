module YaoSym

# abstract type IsSymbolic end
# struct Symbolic <: IsSymbolic end
# struct Numeric <: IsSymbolic end
# IsSymbolic(x) = Numeric()
# isleaf(x) = false

# include("expr.jl")

# include("numbers.jl")
include("register.jl")
include("instruct.jl")
include("blocks.jl")
# include("dirac_str.jl")

end # module
