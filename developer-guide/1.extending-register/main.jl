# # Extending Register: an echo register

# We show how to extend a register that prints the instructions to standard output
# instead of actually exexcuting the instructions.

using Yao

# First you will need to define your own subtype that contains
# your desired data structure

mutable struct EchoReg{B} <: AbstractRegister{B}
    nactive::Int
    nqubits::Int
end

# Then we need to define the most basic API: how many qubits are there

Yao.nactive(reg::EchoReg) = reg.nactive
Yao.nqubits(reg::EchoReg) = reg.nqubits

# And define some instructions, as an echo register, we will just keep printing what we are asked to exexcute

function Yao.instruct!(::EchoReg{B}, args...) where {B, G}
    str = join(string.(args), ", ")
    println("calls: instruct!(reg, $str)")
end

function Yao.focus!(reg::EchoReg{B}, locs) where {B}
    println("focus -> $locs")
    reg.nactive = length(locs)
    return true
end

function Yao.relax!(reg::EchoReg{B}, locs; to_nactive=nqubits(reg)) where {B}
    reg.nactive = to_nactive
    println("relax -> $locs\\$to_nactive")
    return true
end

function Yao.measure!(rng, ::ComputationalBasis, reg::EchoReg{B}, locs) where {B}
    println("measure -> $locs")
    return true
end

# Now we can check what will happen!
r = EchoReg{10}(3, 2)
r |> put(3, 2=>X) |> control(3, 3, 2=>X) |> concentrate(3, put(1, 1=>X), 2:2) |> measure!

# But when we still require some more information from you

r |> cache(X)

# An `NotImplementedError` will be thrown, no worries!
