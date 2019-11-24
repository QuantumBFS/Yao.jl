# # Extending an echo register.

# New registers can be defined by dispatching "instruction" interface to new register types,
# as an example, an echo register has been implemented

using YaoBase
using YaoBlocks
using Test

# ## Define a new type of register
mutable struct EchoReg{B} <: AbstractRegister{B}
    nactive::Int
    nqubits::Int
end
YaoBase.nactive(reg::EchoReg) = reg.nactive
YaoBase.nqubits(reg::EchoReg) = reg.nqubits

# ## Define the instruction set
# The instruction set includes `instruct!`, `measure!` and `focus!` & `relax`.
function YaoBase.instruct!(::EchoReg{B}, args...) where {B, G}
    println("calls: instruct!(reg, $(join(string.(args), ", ")))")
end

function YaoBase.measure!(rng, ::ComputationalBasis, reg::EchoReg{B}, locs) where {B}
    println("measure -> $locs")
    return true
end

function YaoBase.focus!(reg::EchoReg{B}, locs) where {B}
    println("focus -> $locs")
    reg.nactive = length(locs)
    return true
end

function YaoBase.relax!(reg::EchoReg{B}, locs; to_nactive=nqubits(reg)) where {B}
    reg.nactive = to_nactive
    println("relax -> $locs/$to_nactive")
    return true
end

@testset "test ArrayRegister extension" begin
    reg = EchoReg{10}(3, 5)
    @test_throws NotImplementedError reg |> cache(X)
    @test reg |> put(3, 2=>X) |> control(3, 3, 2=>X) |> concentrate(3, put(1, 1=>X), 2:2) |> measure!
end
