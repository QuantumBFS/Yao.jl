using YaoAPI
using YaoBlocks
using Test

mutable struct EchoReg <: AbstractRegister{2}
    nactive::Int
    nqubits::Int
end
YaoAPI.nactive(reg::EchoReg) = reg.nactive
YaoAPI.nqudits(reg::EchoReg) = reg.nqubits

function YaoAPI.instruct!(::EchoReg, ::Val{G}, locs, args...) where {G}
    println("apply -> $G on $locs")
    return true
end

function YaoAPI.focus!(reg::EchoReg, locs)
    println("focus -> $locs")
    reg.nactive = length(locs)
    return true
end

function YaoAPI.relax!(reg::EchoReg, locs; to_nactive = nqubits(reg))
    reg.nactive = to_nactive
    println("relax -> $locs/$to_nactive")
    return true
end

function YaoAPI.measure!(
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
