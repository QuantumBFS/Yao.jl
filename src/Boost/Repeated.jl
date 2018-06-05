GATES = [:X, :Y, :Z]

for (G, MATFUNC) in zip(GATES, [:xgate, :ygate, :zgate])
    GGate = Symbol(G, :Gate)
    @eval function mat(rb::RepeatedBlock{GT, N, MT}) where {GT <: $GGate, N, MT}
        $MATFUNC(MT, N, rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{<:XGate})
    if nremains(r) == 0
        xapply!(vec(state(r)), rb.lines)
    else
        xapply!(state(r), rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{<:YGate})
    if nremains(r) == 0
        yapply!(vec(state(r)), rb.lines)
    else
        yapply!(state(r), rb.lines)
    end
end

function apply!(r::AbstractRegister{1}, rb::RepeatedBlock{<:ZGate})
    if nremains(r) == 0
        zapply!(vec(state(r)), rb.lines)
    else
        zapply!(state(r), rb.lines)
    end
end


function apply!(r::AbstractRegister, rb::RepeatedBlock{<:XGate})
    xapply!(state(r), rb.lines)
end

function apply!(r::AbstractRegister, rb::RepeatedBlock{<:YGate})
    yapply!(state(r), rb.lines)
end

function apply!(r::AbstractRegister, rb::RepeatedBlock{<:ZGate})
    zapply!(state(r), rb.lines)
end
