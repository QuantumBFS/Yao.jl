module Boost

using ..Registers
using ..Blocks
using ..Intrinsics
using ..LuxurySparse

import ..Blocks: mat, apply!

include("gates.jl")
include("applys.jl")

include("Control.jl")
include("Repeated.jl")

end