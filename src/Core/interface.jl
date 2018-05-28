include("gates.jl")

struct XGate{MT} <: PrimitiveBlock{1, MT}
end

function apply!(r::Register, c::RepeatedBlock{N, MT, XGate{MT}}) where {N, MT}
    for each in c
        apply!(r, each)
    end
    r
end

# to -> sub-blocks
blocks(rb::RepeatedBlock{N, MT, XGate{MT}}) where {N, MT} = [rb.unit]

function mat(rb::RepeatedBlock{N, XGate{MT}}) where {N, MT}
end
