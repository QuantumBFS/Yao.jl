module Boost

using ..Registers
using ..Blocks
using ..Intrinsics
using ..LuxurySparse

import ..Blocks: mat, apply!

export general_controlled_gates
export xgate, ygate, zgate
export cxgate, cygate, czgate
export controlled_U1

export xapply!, yapply!, zapply!
export cxapply!, cyapply!, czapply!

include("gates.jl")
include("applys.jl")

include("Control.jl")
include("Repeated.jl")

end