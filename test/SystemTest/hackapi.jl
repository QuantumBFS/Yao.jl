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

include("utils.jl")

PrimitiveBlock = String
Sequence = Vector{PrimitiveBlock}
Register = Vector{Complex128}

# circuit iterator
mutable struct Iter
    psi :: Register
    vals::Sequence
    signal::Int
end

import Base.Iterators: start, next, done
import Base.length, Base.append!
function start(iter::Iter)
    return 1
end
function next(iter::Iter, state)
    iter.psi[1] = 1/sqrt(2)
    iter.psi[end] = -1/sqrt(2)
    d = Dict("iblock"=>state, "current"=> iter.vals[state], "next"=>state < length(iter)?iter.vals[state+1]:nothing, "cache_info"=>2)
    return d, state+1
end
function done(iter::Iter, state)
    return state == 4
end
length(iter::Iter) = length(iter.vals)

export zero_state, X, rotation_block, c
function zero_state(num_bit::Int)
    psi = zeros(Complex128, 1<<num_bit)
    psi[1] = 1
    psi
end
X(num_bit::Int, ibit::Int) = "X($(ibit)/$(num_bit))"
H(num_bit::Int, ibit::Int) = "H($(ibit)/$(num_bit))"
H(num_bit::Int, ibit::Range) = "H($(collect(ibit))/$(num_bit))"
rotation_block(num_bit::Int) = "Rot($(num_bit))"

function c(pos::Int)
    controled_gate(gate::PrimitiveBlock) = "C($(pos))-"*gate
end

export cache, mask, cache_signal
cache(block::PrimitiveBlock; level::Int=1, recursive::Bool=false) = block*"<- Cached"
cache(block::Sequence; level::Int=1, recursive::Bool=false) = [cache(b) for b in block]
function cache(;level::Int=1, recursive::Bool=false)
    func(block::Union{PrimitiveBlock, Sequence}) = cache(block, level=level, recursive=recursive)
end

function cache_signal(signal::Int)
    function func(iter::Iter)
        iter.signal = signal
        iter
    end
end

clear_cache(sequence::Sequence) = append!(sequence, ["<- clear cache"])

function mask(mask::Array{Bool, 1})
    function func(block::Union{PrimitiveBlock, Sequence})
        if typeof(block) == PrimitiveBlock
            return block*"<- Masked as $(mask)"
        else
            return [func(b) for b in block]
        end
    end
end

export sequence, >>, scatter_params
sequence(list::Sequence = PrimitiveBlock[]) = list
append!(sequence::Sequence, block::String) = append!(sequence, [block])
nparam(sequence::Sequence) = 500

pipline(psi::Register, sequence::Sequence) = Iter(psi, sequence, 3)
pipline(iter::Iter, sequence::Sequence) = Iter(iter.psi, vcat(iter.vals, sequence), iter.signal)
>> = pipline

function scatter_params(params::Vector{Float64})  # size == nparam?
    function func(list::Sequence)
        for i in 1:length(list)
            list[i] = list[i]#*"<- ($(params[i]))"
        end
        list
    end
end

function gather_params(sequence::Sequence)
    return randn(nparam(sequence))
end

function add_params(params::Vector{Float64})  # size == nparam?
    function func(list::Sequence)
        for i in 1:length(list)
            list[i] = list[i]#*"<- + ($(params[i]))"
        end
        list
    end
end

nqubit(sequence::Sequence) = 6
