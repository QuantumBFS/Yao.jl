for (G, g) in zip(GATES, gATES)
    GATE = Symbol(G, :Gate)
    MATFUNC = Symbol(g, :gate)
    @eval function mat(rb::RepeatedBlock{N, C, GT, MT}) where {N, C, MT, GT <: $GATE}
        $MATFUNC(MT, N, [rb.addrs...])
    end
    @eval function mat(rb::PutBlock{N, 1, GT, MT}) where {N, MT, GT <: $GATE}
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

for (G, g) in zip(GATES, gATES)
    GATE = Symbol(G, :Gate)
    METHOD = Symbol(g, :apply!)
    @eval apply!(r::AbstractRegister{B}, rb::RepeatedBlock{N, C, <:$GATE}) where {B, N, C} = ($METHOD(r.state |> matvec, [rb.addrs...]); r)
    @eval apply!(r::AbstractRegister, pb::PutBlock{N, 1, <:$GATE}) where N = ($METHOD(r.state |> matvec, pb.addrs[1]); r)
end
