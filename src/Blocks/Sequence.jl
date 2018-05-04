# TODO: nqubit inference

struct Sequence <: AbstractBlock
    list::Vector
end

sequence(blocks...) = Sequence([blocks...])
(block::Sequence)(reg::Register) = apply!(reg, block)

function apply!(reg::Register, block::Sequence)
    for each in block.list
        apply!(reg, each)
    end
    reg
end

push!(seq::Sequence, block::AbstractBlock) = push!(seq.list, block)

import Base: start, next, done, length, eltype

struct CircuitPlan{N, B, T}
    reg::Register{N, B, T}
    seq::Sequence
end

start(itr::CircuitPlan) = 1, Dict()
done(itr::CircuitPlan, state) = state[1] > length(itr.seq.list)
length(itr::CircuitPlan) = length(itr.seq.list)
eltype(itr::CircuitPlan) = eltype(itr.seq.list)

function next(itr::CircuitPlan, state)
    i, info = state
    block = itr.seq.list[i]
    info["iblock"] = state
    info["current"] = block
    if i < length(itr.seq.list)
        info["next"] = itr.seq.list[i+1]
    end

    if "callback" in keys(info)
        info["callback"](itr.reg)
        delete!(info, "callback")
    end

    apply!(itr.reg, block)
    return info, (i+1, info)
end

import Base: >>
export >>

function >>(reg::Register, block::AbstractBlock)
    CircuitPlan(reg, sequence(block))
end

function >>(plan::CircuitPlan, block::AbstractBlock)
    push!(plan.seq, block)
    plan
end
