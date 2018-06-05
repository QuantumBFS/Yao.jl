GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{GT, N, MT}) where {GT <: $GGate, N, MT}
        $MATFUNC(MT, N, rb.lines)
    end
end
