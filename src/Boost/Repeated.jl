GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{N, MT, GT}) where {N, MT, GT <: $GGate}
        $MATFUNC(MT, N, rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{N, T, <:XGate}) where {N, T}
    if nremain(r) == 0
        xapply!(vec(state(r)), rb.lines)
    else
        xapply!(state(r), rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{N, T, <:YGate}) where {N, T}
    if nremain(r) == 0
        yapply!(vec(state(r)), rb.lines)
    else
        yapply!(state(r), rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{N, T, <:ZGate}) where {N, T}
    if nremain(r) == 0
        zapply!(vec(state(r)), rb.lines)
    else
        zapply!(state(r), rb.lines)
    end
end

function apply!(r::AbstractRegister, rb::RepeatedBlock{N, T, <:XGate}) where {N, T}
    xapply!(state(r), rb.lines)
end

function apply!(r::AbstractRegister, rb::RepeatedBlock{N, T, <:YGate}) where {N, T}
    yapply!(state(r), rb.lines)
end

function apply!(r::AbstractRegister, rb::RepeatedBlock{N, T, <:ZGate}) where {N, T}
    zapply!(state(r), rb.lines)
end
