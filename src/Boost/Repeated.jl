GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, C, GT, MT}) where {N, C, MT, GT <: $GGate}
        $MATFUNC(MT, N, [rb.addrs...])
    end
    @eval function mat(rb::PutBlock{N, 1, GT, MT}) where {N, MT, GT <: $GGate}
        $MATFUNC(MT, N, [rb.addrs...])
    end
end

function apply!(reg::AbstractRegister, rb::RepeatedBlock{N, C, <:MatrixBlock{1}}) where {C, N}
    m = mat(rb.block)
    for addr in rb.addrs
        u1apply!(reg.state |> matvec, m, addr)
    end
    reg
end

function apply!(reg::AbstractRegister, pb::PutBlock{N, 1, <:MatrixBlock{1}}) where {N}
    u1apply!(reg.state |> matvec, mat(pb.block), pb.addrs...)
    reg
end

for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, C, <:$GATE}) where {B, N, C} = ($METHOD(r.state |> matvec, [rb.addrs...]); r)
end

for (GATE, METHOD) in zip([:XGate, :YGate, :ZGate], [:xapply!, :yapply!, :zapply!])
    @eval apply!(r::AbstractRegister, pb::PutBlock{N, 1, <:$GATE}) where N = ($METHOD(r.state |> matvec, [pb.addrs...]); r)
end
