# TODO: nqubit inference

struct Sequence <: AbstractBlock
    list::Vector{Any}
end


function apply!(reg::Register, block::Sequence)
    for each in block.list
        apply!(reg, each)
    end
    reg
end

import Base: push!

push!(seq::Sequence, block::AbstractBlock) = push!(seq.list, block)

function show(io::IO, block::Sequence)
    println(io, "Sequence:")

    for (i, each) in enumerate(block.list)
        print(io, "    ", each)

        if i != length(block.list)
            print(io, "\n")
        end
    end
end

