using YaoBase
using YaoBlocks
using Test

mutable struct EchoReg{B} <: AbstractRegister{B,2}
    nactive::Int
    nqubits::Int
end
YaoBase.nactive(reg::EchoReg) = reg.nactive
YaoBase.nqudits(reg::EchoReg) = reg.nqubits

function YaoBase.instruct!(::EchoReg{B}, ::Val{G}, locs, args...) where {B,G}
    println("apply -> $G on $locs")
    return true
end

function YaoBase.focus!(reg::EchoReg{B}, locs) where {B}
    println("focus -> $locs")
    reg.nactive = length(locs)
    return true
end

function YaoBase.relax!(reg::EchoReg{B}, locs; to_nactive = nqubits(reg)) where {B}
    reg.nactive = to_nactive
    println("relax -> $locs/$to_nactive")
    return true
end

function YaoBase.measure!(
    post::PostProcess,
    ::ComputationalBasis,
    reg::EchoReg{B},
    locs;
    kwargs...,
) where {B}
    println("measure -> $locs, post-process = $post")
    return true
end

@testset "test ArrayRegister extension" begin
    reg = EchoReg{10}(3, 5)
    @test_throws QubitMismatchError reg |> cache(X)
    @test reg |>
          put(3, 2 => X) |>
          control(3, 3, 2 => X) |>
          subroutine(3, put(1, 1 => X), 2:2) |>
          measure!
end
