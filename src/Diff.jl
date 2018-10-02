using Yao
using Yao.Blocks
using Lazy

import Base.parent
import Yao.Blocks: mat, apply!, block, setblock!
using LinearAlgebra, Test, BenchmarkTools

Base.copyto!(reg1::RT, reg2::RT) where {RT<:AbstractRegister} = (copyto!(reg1.state, reg2.state); reg1)
Rotter{N, T} = Union{RotationGate{N, T}, PutBlock{N, <:Any, <:RotationGate, <:Complex{T}}}

"""please don't use the `adjoint` after `Diff`! `adjoint` is reserved for special purpose! (back propagation)"""
mutable struct Diff{N, T, GT<:Rotter{N, T}, RT<:AbstractRegister} <: NonParametricContainer{N, Complex{T}}
    block::GT
    output::RT
    grad::T
    Diff(block::Rotter{N, T}, output::RT) where {N, T, RT} = new{N, T, typeof(block), RT}(block, output, T(0))
    Diff(block::Rotter{N, T}) where {N, T} = Diff(block, zero_state(N))
end
block(df::Diff) = df.block
setblock!(df::Diff, blk::AbstractBlock) = (df.block = blk; df)

@forward Diff.block mat
parent(df::Diff) = df.block
Base.adjoint(df::Diff) = (df.block = df.block'; Adjoint(df))
function apply!(reg::AbstractRegister, df::Diff)
    apply!(reg, parent(df))
    df.output = copy(reg)
    reg
end
function apply!(δ::AbstractRegister, adf::Adjoint{<:Any, <:Diff})
    df = adf |> parent
    df.grad = (df.output |> generator(parent(df)))' * δ * 0.5im
    apply!(δ, parent(df)')
end
generator(rot::RotationGate) = rot.U

function gradient(U::AbstractBlock, δ::AbstractRegister)
    δ |> U'
    local grad = Float64[]
    blockfilter(U) do x
        x isa Diff && push!(grad, x.grad)
    end
    grad
end

import Base: diff
import Yao.Blocks: print_block
function print_block(io::IO, df::Diff)
    print(io, parent(df))
    print(io, "'")
end
#=
function diff(c::CompositeBlock)
    c.blocks = [ci |> diff for ci in c]
end
function diff(c::AbstractContainer)
    if block(c) isa Rotter
        setblock!(c, block(c) |> diff)
    else
        c |> block |> diff
    end
end
diff(c::ControlBlock) = c
=#

qdiff(block::Rotter{N}, reg::AbstractRegister=zero_state(N)) where N = Diff(block, reg)
qdiff(reg::AbstractRegister) = block -> qdiff(block, reg)

function testfunc(circuit)
    function psi_loss(θ)
        dispatch!(circuit, θ)
        op = put(X, 3)
        psi = zero_state(nqubits(circuit)) |> circuit
        op, psi, expect(op, psi)
    end
end

@testset "grad" begin
    circuit = chain(4, put(4, 3=>Rx(0.5)) |> qdiff, control(2, 1=>X), put(4, 4=>Ry(0.2)) |> qdiff)
    lossfunc = testfunc(circuit)
    θ = [0.1, 0.2]
    op, ψ, loss = lossfunc(θ)

    # get gradient
    δ = ψ |> op
    g1 = gradient(circuit, δ)

    g2 = zero(θ)
    η = 0.01
    for i in 1:length(θ)
        θ1 = copy(θ)
        θ2 = copy(θ)
        θ1[i] -= 0.5η
        θ2[i] += 0.5η
        g2[i] = (lossfunc(θ2)[3] - lossfunc(θ1)[3])/η
    end
    println(g1)
    println(g2)
end

rx = rot(X, 0.3)
Diff(put(5, 2=>rx))

rotter(noleading::Bool=false, notrailing::Bool=false) = noleading ? (notrailing ? Rx(0) : chain(Rx(0), Rz(0))) : (notrailing ? chain(Rz(0), Rx(0)) : chain(Rz(0), Rz(0), Rz(0)))

function diff_circuit(n, nlayer, pairs)
    circuit = chain(n)

    for i = 1:(nlayer + 1)
        if i!=1  push!(circuit, cnot_entangler(pairs) |> cache) end
        push!(circuit, put(n, rotter(i==1, i==nlayer+1)))
    end
    dispatch!(circuit, rand(nparameters(circuit))*2π)
end

f(psi) = expect(X, psi)
function opdiff(rg::RotationGate, ireg, oreg)
    imag(oreg' * (ireg |> parent(rg)))
end

using BenchmarkTools, Test
@testset "Constrcut" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = Diff(block, copy(reg))
    @test df.grad == 0
    @test nqubits(df) == 4

    df2 = Diff(rot(CNOT, 0.3))
    @test df2.grad == 0
    @test nqubits(df2) == 2
end

@testset "opdiff" begin
    reg = rand_state(4)
    block = put(4, 2=>rot(X, 0.3))
    df = Diff(block, copy(reg))

    c = diff_circuit(4, 2, [1=>2, 2=>3, 3=>4, 4=>1])
end
