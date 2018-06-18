GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, MT, GT}) where {N, MT, GT <: $GGate}
        $MATFUNC(MT, N, rb.addrs)
    end
end

apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, T, <:MatrixBlock{1}}) where {B, N, T} = (u1apply!(r.state |> matvec, mat(rb.block), rb.addrs[]); r)
mat(rb::RepeatedBlock{N}) where N = hilbertkron(N, fill(mat(rb.block), length(rb.addrs)), rb.addrs)
for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, T, <:$GATE}) where {B, N, T} = ($METHOD(r.state |> matvec, rb.addrs); r)
end
