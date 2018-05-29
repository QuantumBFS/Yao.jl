# Pretty Printing
function show(io::IO, g::PhaseGate{:global})
    print(io, "Global Phase Gate:", g.theta)
end

function show(io::IO, g::PhaseGate{:shift})
    print(io, "Phase Shift Gate:", g.theta)
end

function show(io::IO, R::RotationGate{T, GT}) where {T, GT}
    print(io, "Rot ", R.U, ": ", R.theta)
end

function show(io::IO, c::ChainBlock{N, T}) where {N, T}
    println(io, "ChainBlock{$N, $T}")
    for i in eachindex(c.blocks)
        if isassigned(c.blocks, i)
            print(io, "\t", c.blocks[i])
        else
            print(io, "\t", "#undef")
        end

        if i != endof(c.blocks)
            print(io, "\n")
        end
    end
end

function show(io::IO, k::KronBlock{N, T}) where {N, T}
    println(io, "KronBlock{", N, ", ", T, "}")

    if length(k) == 0
        print(io, "  with 0 blocks")
        return
    end

    for i in eachindex(k.addrs)
        print(io, "  ", k.addrs[i], ": ", k.blocks[i])
        if i != endof(k.addrs)
            print(io, "\n")
        end
    end
end

function show(io::IO, m::Roller{N, M, T, BT}) where {N, M, T, BT}
    print(io, "Roller on $N lines ($M blocks in total)")

    if !isempty(m.blocks)
        print(io, "\n")
    end

    for i in eachindex(m.blocks)
        print(io, "\t", i, ": ", m.blocks[i])

        if i != endof(m.blocks)
            print(io, "\n")
        end
    end
end

# pretty printing

function show(io::IO, ctrl::ControlBlock{BT, N, T}) where {BT, N, T}
    println(io, "control:")
    println(io, "\ttotal: $N")
    println(io, "\t$(ctrl.ctrl_qubits) control")
    print(io, "\t$(ctrl.block) at $(ctrl.addr)")
end


# This part is copied and tweaked from Keno/AbstractTrees.jl

# struct BlockTreeCharSet
#     mid
#     terminator
#     skip
#     dash
# end

# # Default Charset
# BlockTreeCharSet() = BlockTreeCharSet('├','└','│','─')

# function print_children(io::IO, c::ChainBlock, index)
#     if isassigned(c.blocks, i)
#         print(io, c.blocks[index])
#     else
#         print(io, "#undef")
#     end
# end

# function print_node(io::IO, c::ChainBlock{N, T}) where N where T
#     print(io, "ChainBlock{", N, ", ", T, "}")
# end

# isparent(c::CompositeBlock) = true
# isparent(c::AbstractBlock) = false

# function print_tree(io::IO, entry::ChainBlock, charset, depth)
#     print_node(io, entry)

#     for each in entry.blocks
#         print_prefix(io, charset, depth)
#         print_tree(io, each)
#     end
# end
