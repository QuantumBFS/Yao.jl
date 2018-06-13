GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, MT, GT}) where {N, MT, GT <: $GGate}
        $MATFUNC(MT, N, rb.addrs)
    end
end

for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, T, <:$GATE}) where {B, N, T} = ($METHOD(r.state |> matvec, rb.addrs); r)
end
