module YaoToEinsum

using Yao, OMEinsum
using LinearAlgebra

export yao2einsum, add_gate!

struct EinBuilder{T}
    slots::Vector{Int}
    labels::Vector{Vector{Int}}
    tensors::Vector{AbstractArray{T}}
    maxlabel::Base.RefValue{Int}
end

Yao.nqubits(eb::EinBuilder) = length(eb.slots)

function EinBuilder(n::Int)
    EinBuilder(collect(1:n), Vector{Int}[], AbstractArray{ComplexF64}[], Ref(n))
end
newlabel!(eb::EinBuilder) = (eb.maxlabel[] += 1; eb.maxlabel[])

function add_product_state!(eb::EinBuilder{T}, bitstring) where T
    for i=1:nqubits(eb)
        push!(eb.tensors, bitstring[i] == 0 ? T[1, 0] : T[0, 1])
        push!(eb.labels, [eb.slots[i]])
    end
    return eb
end

function add_gate!(eb::EinBuilder{T}, b::PutBlock{N,C}) where {T, N,C}
    return add_matrix!(eb, C, mat(T, b.content), collect(b.locs))
end
# general and diagonal gates
function add_matrix!(eb::EinBuilder{T}, k::Int, m::AbstractMatrix, locs::Vector) where T
    if !isdiag(m)
        nlabels = [newlabel!(eb) for _=1:k]
        push!(eb.tensors, reshape(Matrix{T}(m), fill(2, 2k)...))  # need to check
        push!(eb.labels, [nlabels..., eb.slots[locs]...])
        eb.slots[locs] .= nlabels
    else
        push!(eb.tensors, reshape(Vector{T}(diag(m)), fill(2, k)...))  # need to check
        push!(eb.labels, eb.slots[locs])
    end
    return eb
end
# swap gate
function add_gate!(eb::EinBuilder{T}, b::PutBlock{N,2,ConstGate.SWAPGate}) where {T,N}
    lj = eb.slots[b.locs[2]]
    eb.slots[b.locs[2]] = eb.slots[b.locs[1]]
    eb.slots[b.locs[1]] = lj
    return eb
end

# control gates
function add_gate!(eb::EinBuilder{T}, b::ControlBlock{N,BT,C,M}) where {T, N,BT,C,M}
    return add_controlled_matrix!(eb, M, mat(T, b.content), collect(b.locs), collect(b.ctrl_locs), collect(b.ctrl_config))
end
function add_controlled_matrix!(eb::EinBuilder{T}, k::Int, m::AbstractMatrix, locs::Vector, control_locs, control_vals) where T
    if length(control_locs) == 0
        return add_matrix!(eb, k, m, locs)
    end
    sig = eb.slots[control_locs[1]]
    val = control_vals[1]
    for i=1:length(control_locs)-1
        newsig = newlabel!(eb)
        push!(eb.labels, [newsig,eb.slots[control_locs[i+1]],sig])
        push!(eb.tensors, and_gate(T, control_vals[i+1], val))
        sig = newsig
        val = 1
    end
    if !isdiag(m)
        t1 = reshape(Matrix{T}(m), fill(2, 2k)...)
        t2 = reshape(Matrix{T}(I, 1<<k, 1<<k), fill(2, 2k)...)
        if val == 1
            t1, t2 = t2, t1
        end
        push!(eb.tensors, cat(t1, t2; dims=2k+1))  # need to check
        nlabels = [newlabel!(eb) for _=1:k]
        push!(eb.labels, [nlabels..., eb.slots[locs]..., sig])
        eb.slots[locs] .= nlabels
    else
        t1 = reshape(Vector{T}(diag(m)), fill(2, k)...)
        t2 = reshape(ones(T, 1<<k), fill(2, k)...)
        if val == 1
            t1, t2 = t2, t1
        end
        push!(eb.tensors, cat(t1, t2; dims=k+1))  # need to check
        push!(eb.labels, [eb.slots[locs]..., sig])
    end
    return eb
end

function and_gate(::Type{T}, a::Int, b::Int) where T
    m = zeros(T, 2, 2, 2)
    for v1 in (0, 1)
        for v2 in (0, 1)
            # the first is output
            m[(v1==a && v2==b)+1, v1+1,v2+1] = 1
        end
    end
    return m
end

function add_gate!(eb::EinBuilder, b::ChainBlock)
    for ib in subblocks(b)
        add_gate!(eb, ib)
    end
    return eb
end

function add_gate!(eb::EinBuilder, b::AbstractBlock)
    B = to_basic_types(b)
    if typeof(B) == typeof(b)
        throw("block of type `$(typeof(b))` can not be converted to tensor network representation!")
    else
        add_gate!(eb, B)
    end
    return eb
end

function yao2einsum(circuit::AbstractBlock; initial_state=nothing, final_state=nothing)
    n = nqubits(circuit)
    eb = EinBuilder(nqubits(circuit))
    openindices = Int[]
    if initial_state===nothing
        append!(openindices, eb.slots)
    else
        @assert n == length(initial_state)
        add_product_state!(eb, initial_state)
    end
    add_gate!(eb, circuit)
    if final_state===nothing
        prepend!(openindices, eb.slots)
    else
        @assert n == length(final_state)
        add_product_state!(eb, final_state)
    end
    return build_einsum(eb, openindices)
end

function build_einsum(eb::EinBuilder, openindices)
    return EinCode(eb.labels, openindices), eb.tensors
end

end
