module Boost

using ..Blocks
using ..Intrinsics
using ..LuxurySparse

import ..Blocks: mat

include("gates.jl")
include("Control.jl")
include("Repeated.jl")

end