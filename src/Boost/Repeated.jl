GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, C, GT, MT}) where {N, C, MT, GT <: $GGate}
        $MATFUNC(MT, N, [rb.addrs...])
    end
end

apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, 1, <:MatrixBlock{1}}) where {B, N} = (u1apply!(r.state |> matvec, mat(rb.block), rb.addrs...); r)
for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, C, <:$GATE}) where {B, N, C} = ($METHOD(r.state |> matvec, [rb.addrs...]); r)
end
