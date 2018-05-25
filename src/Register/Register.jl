export nqubit, nactive, nremain, nbatch, address, state, statevec, focus!

export AbstractRegister, Register

# factories
export register, zero_state, rand_state, randn_state

import Base: eltype, copy, similar, *
import Base: show

include("Core.jl")
include("Default.jl")

# NOTE: these two are not implemented
include("GPU.jl")
include("MPS.jl")
