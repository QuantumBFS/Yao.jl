using YaoBase
using YaoBlocks
using Test

mutable struct EchoReg <: AbstractRegister{2}
    nactive::Int
    nqubits::Int
end
YaoBase.nactive(reg::EchoReg) = reg.nactive
YaoBase.nqudits(reg::EchoReg) = reg.nqubits

function YaoBase.instruct!(::EchoReg, ::Val{G}, locs, args...) where {G}
    println("apply -> $G on $locs")
    return true
end

function YaoBase.focus!(reg::EchoReg, locs)
    println("focus -> $locs")
    reg.nactive = length(locs)
    return true
end

function YaoBase.relax!(reg::EchoReg, locs; to_nactive = nqubits(reg))
    reg.nactive = to_nactive
    println("relax -> $locs/$to_nactive")
    return true
end

function YaoBase.measure!(
    post::PostProcess,
    ::ComputationalBasis,
    reg::EchoReg,
    locs;
    kwargs...,
)
    println("measure -> $locs, post-process = $post")
    return true
end

@testset "test ArrayRegister extension" begin
    reg = EchoReg(3, 5)
    @test_throws QubitMismatchError reg |> cache(X)
    @test reg |>
          put(3, 2 => X) |>
          control(3, 3, 2 => X) |>
          subroutine(3, put(1, 1 => X), 2:2) |>
          measure!
end
