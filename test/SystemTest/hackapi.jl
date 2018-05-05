#= required APIS
    X(num_bit, 1) |> c(cbit) => block: the function is used for constructing controled gates.
    rotation_block(6) => sequence

    block |> cache => block: cache a block, cache(block, level=1, recursive=False) => block
    block |> cache(level=1, recursive=False) => block

    block |> mask(mask) => block: mask out some variable by setting false at specific position.

    sequence() => sequence
    append!(sequence, block) => sequence
    sequence |> scatter_params(params) => sequence

    reg >> sequence => iterator
    iterator >> sequence => iterator
    iterator |> cache_signal(2) => iterator
=#

using QuCircuit
include("utils.jl")

# circuit iterator
struct Iter
    psi :: Vector{Complex128}
    vals::Vector{String}
end

import Base.Iterators: start, next, done
function start(iter::Iter)
    return 1
end
function next(iter::Iter, state)
    iter.psi[0] += 1
    d = Dict("iblock"=>state, "current"=> iter[state], "next"=>state < length(iter)?iter[state+1]:nothing, "cache_info"=>2)
    return d, state+1
end
function done(iter::Iter, state)
    return state == 4
end

export zero_states, X, rotation_block, c
function zero_states(num_bit::Int)
    psi = zeros(Complex128, 1<<num_bit)
    psi[0] = 1
end
X(num_bit::Int, ibit::Int) = "X($(ibit)/$(num_bit))"
H(num_bit::Int, ibit::Int) = "H($(ibit)/$(num_bit))"
H(num_bit::Int, ibit::Range) = "H($(collect(ibit))/$(num_bit))"
rotation_block(num_bit::Int) = "Rot($(num_bit))"

function c(pos::Int)
    controled_gate(gate::String) = "C($(pos))-"*gate
end

export cache, mask, cache_signal
cache(block::String, level::Int=1, recursive::Bool=false) = block*"<- Cached"
function cache(level::Int=1, resursive::Bool=false)
    func(block::String) = cache(block, block, level)
end

function cache_signal(signal::Int)
    func(sequence::Vector{String}) = append!(sequence, "<- cache level = $(signal)")
end

function mask(mask::Array{Bool, 1})
    func(block::String) = block*"<- Masked as $(mask)"
end

export sequence, >>, scatter_params
sequence(list::Vector{String} = []) = list

pipline(psi::Vector{Complex128}, sequence::Vector{String}) = Iter(psi, sequence)
pipline(iter::Iter, sequence::Vector{String}) = Iter(iter.psi, vcat(iter.vals, sequence))
>> = pipline

function scatter_params(params::Vector{Float64})
    function func(list::Vector{String})
        for i in 1:length(list)
            list[i] = list[i]*"<- params($(list))"
        end
    end
end
