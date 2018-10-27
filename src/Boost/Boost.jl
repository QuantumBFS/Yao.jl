module Boost

using ..Registers
using ..Blocks
using ..Intrinsics
using LuxurySparse
using LinearAlgebra

import ..Blocks: mat, apply!
import ..Intrinsics: u1apply!, unapply!, general_controlled_gates, general_c1_gates, unrows!

export xgate, ygate, zgate, tgate, tdaggate, sgate, sdaggate
export cxgate, cygate, czgate, ctgate, ctdaggate, csgate, csdaggate
export controlled_U1, controller

export xapply!, yapply!, zapply!, tapply!, tdagapply!, sapply!, sdagapply!, u1apply!
export cxapply!, cyapply!, czapply!, ctapply!, ctdagapply!, csapply!, csdagapply!

include("gates.jl")
include("applys.jl")

include("Control.jl")
include("Repeated.jl")

end
