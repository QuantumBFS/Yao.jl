include("gates.jl")
import QuCircuit: PrimitiveBlock, CompositeBlock

struct XGate{MT} <: PrimitiveBlock{1, MT}
end

struct RepeatedBlock{N, MT, GT{MT}} <: CompositeBlock{N, MT}
    unit::GT{MT}
end

struct Controlled{N, MT, GT{MT}} <: CompositeBlock{M, MT}
    target::GT{MT}
end

#function apply!(r::Register, c::RepeatedBlock{N, MT, XGate{MT}}) where {N, MT}
#end

# to -> sub-blocks
blocks(rb::RepeatedBlock{N, MT, XGate{MT}}) where {N, MT} = [rb.unit]

function mat(rb::RepeatedBlock{N, XGate{MT}}) where {N, MT}
end

for (GATETYPE, MATFUNC) in zip([:XGate, :YGate, :ZGate], [:cxgate, :cygate, :czgate])
    @eval function mat(cb::Controlled{N, $GATETYPE{MT}}, cbit, ibit) where {N, MT}
        $MATFUNC(N, cbit, ibit)
    end
end

import Compat.Test
@test mat(Controlled{2}(XGate{ComplexF64}()), 2, 1) == CNOT_MAT
