# import Base: start, next, done, length, eltype

# struct CircuitPlan{B, T}
#     reg::Register{B, T}
#     seq::Sequence
# end

# start(itr::CircuitPlan) = 1, Dict()
# done(itr::CircuitPlan, state) = state[1] > length(itr.seq.list)
# length(itr::CircuitPlan) = length(itr.seq.list)
# eltype(itr::CircuitPlan) = eltype(itr.seq.list)

# function next(itr::CircuitPlan, state)
#     i, info = state
#     block = itr.seq.list[i]
#     info["iblock"] = i
#     info["current"] = block
#     if i < length(itr.seq.list)
#         info["next"] = itr.seq.list[i+1]
#     end

#     apply!(itr.reg, block)
#     return info, (i+1, info)
# end

# import Base: >>
# export >>

# function >>(reg::Register, block::Sequence)
#     CircuitPlan(reg, block)
# end

# function >>(reg::Register, block::AbstractBlock)
#     CircuitPlan(reg, Sequence(block))
# end

# function >>(plan::CircuitPlan, block::AbstractBlock)
#     push!(plan.seq, block)
#     plan
# end

# function show(io::IO, plan::CircuitPlan)
#     println(io, "Circuit Excution Plan:")

#     println(io, plan.reg)
#     println(io, "----")
#     for (i, each) in enumerate(plan.seq.list)
#         print(io, "    ", each)

#         if i != length(plan.seq.list)
#             print(io, "\n")
#             println(io, "----")
#         end
#     end
# end
