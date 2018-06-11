GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, MT, GT}) where {N, MT, GT <: $GGate}
        $MATFUNC(MT, N, rb.lines)
    end
end

matvec(x::Matrix) = size(x, 2) == 1 ? squeeze(x, 2) : x

for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, T, <:$GATE}) where {B, N, T} = ($METHOD(r.state |> matvec, rb.lines); r)
end
