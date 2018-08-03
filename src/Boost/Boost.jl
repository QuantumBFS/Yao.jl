module Boost

using ..Registers
using ..Blocks
using ..Intrinsics
using ..LuxurySparse
using LinearAlgebra

import ..Blocks: mat, apply!
import ..Intrinsics: u1apply!, unapply!, general_controlled_gates, general_c1_gates, unrows!

export xgate, ygate, zgate
export cxgate, cygate, czgate
export controlled_U1, controller

export xapply!, yapply!, zapply!, u1apply!
export cxapply!, cyapply!, czapply!

include("gates.jl")
include("applys.jl")

include("Control.jl")
include("Repeated.jl")

end
