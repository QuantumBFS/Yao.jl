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
function add_tensor!(eb::EinBuilder{T}, tensor::AbstractArray{T,N}, labels::Vector{Int}) where {N,T}
    @assert N == length(labels)
    push!(eb.tensors, tensor)
    push!(eb.labels, labels)
end

function EinBuilder(::Type{T}, n::Int) where T
    EinBuilder(collect(1:n), Vector{Int}[], AbstractArray{T}[], Ref(n))
end
newlabel!(eb::EinBuilder) = (eb.maxlabel[] += 1; eb.maxlabel[])

function add_gate!(eb::EinBuilder{T}, b::PutBlock{D,C}) where {T,D,C}
    return add_matrix!(eb, C, mat(T, b.content), collect(b.locs))
end
# general and diagonal gates
function add_matrix!(eb::EinBuilder{T}, k::Int, m::AbstractMatrix, locs::Vector) where T
    if !isdiag(m)
        nlabels = [newlabel!(eb) for _=1:k]
        add_tensor!(eb, reshape(Matrix{T}(m), fill(2, 2k)...), [nlabels..., eb.slots[locs]...])
        eb.slots[locs] .= nlabels
    else
        add_tensor!(eb, reshape(Vector{T}(diag(m)), fill(2, k)...), eb.slots[locs])
    end
    return eb
end
# swap gate
function add_gate!(eb::EinBuilder{T}, b::PutBlock{2,2,ConstGate.SWAPGate}) where {T,N}
    lj = eb.slots[b.locs[2]]
    eb.slots[b.locs[2]] = eb.slots[b.locs[1]]
    eb.slots[b.locs[1]] = lj
    return eb
end

# control gates
function add_gate!(eb::EinBuilder{T}, b::ControlBlock{BT,C,M}) where {T, BT,C,M}
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
        add_tensor!(eb, and_gate(T, control_vals[i+1], val), [newsig,eb.slots[control_locs[i+1]],sig])
        sig = newsig
        val = 1
    end
    if !isdiag(m)
        t1 = reshape(Matrix{T}(m), fill(2, 2k)...)
        t2 = reshape(Matrix{T}(I, 1<<k, 1<<k), fill(2, 2k)...)
        if val == 1
            t1, t2 = t2, t1
        end
        nlabels = [newlabel!(eb) for _=1:k]
        add_tensor!(eb, cat(t1, t2; dims=2k+1), [nlabels..., eb.slots[locs]..., sig])
        eb.slots[locs] .= nlabels
    else
        t1 = reshape(Vector{T}(diag(m)), fill(2, k)...)
        t2 = reshape(ones(T, 1<<k), fill(2, k)...)
        if val == 1
            t1, t2 = t2, t1
        end
        add_tensor!(eb, cat(t1, t2; dims=k+1), [eb.slots[locs]..., sig])
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
    B = Optimise.to_basictypes(b)
    if typeof(B) == typeof(b)
        throw("block of type `$(typeof(b))` can not be converted to tensor network representation!")
    else
        add_gate!(eb, B)
    end
    return eb
end

"""
    yao2einsum(circuit, initial_state::Dict, final_state::Dict)
    yao2einsum(circuit; initial_state=Dict(), final_state=Dict())

Transform a Yao `circuit` to a generalized tensor network (einsum) notation.
This function returns a 2-tuple of (einsum code, input tensors).
`initial_state` and `final_state` are dictionaries that specify the initial state and final state as product states,
e.g. a vector `Dict(1=>1, 2=>1, 3=>0, 4=>1)` specifies a product state `|1⟩⊗|1⟩⊗|0⟩⊗|1⟩`.
If an qubit in initial state or final state is not specified, it will be treated as an open edge.

```jldoctest
julia> using YaoToEinsum, Yao

julia> c = chain(3, put(3, 2=>X), put(3, 1=>Y), control(3, 1, 3=>Y))
nqubits: 3
chain
├─ put on (2)
│  └─ X
├─ put on (1)
│  └─ Y
└─ control(1)
   └─ (3,) Y


julia> yao2einsum(c; initial_state=Dict(1=>0, 2=>1), final_state=Dict(1=>ArrayReg([0.6, 0.8im]), 2=>1))
(1, 2, 4∘2, 5∘1, 6∘3∘5, 5, 4 -> 6∘3, AbstractArray{ComplexF64}[[1.0 + 0.0im, 0.0 + 0.0im], [0.0 + 0.0im, 1.0 + 0.0im], [0.0 + 0.0im 1.0 + 0.0im; 1.0 + 0.0im 0.0 + 0.0im], [0.0 + 0.0im 0.0 - 1.0im; 0.0 + 1.0im 0.0 + 0.0im], [1.0 + 0.0im 0.0 + 0.0im; 0.0 + 0.0im 1.0 + 0.0im;;; 0.0 + 0.0im 0.0 - 1.0im; 0.0 + 1.0im 0.0 + 0.0im], [0.6 + 0.0im, 0.0 + 0.8im], [0.0 + 0.0im, 1.0 + 0.0im]])
```
"""
function yao2einsum(circuit::AbstractBlock{D}; initial_state::Dict=Dict{Int,Int}(), final_state::Dict=Dict{Int,Int}()) where {D}
    T = promote_type(ComplexF64, dict_regtype(initial_state), dict_regtype(final_state), Yao.parameters_eltype(circuit))
    vec_initial_state = Dict{Int,ArrayReg{D,T}}([k=>render_single_qubit_state(T, v) for (k, v) in initial_state])
    vec_final_state = Dict{Int,ArrayReg{D,T}}([k=>render_single_qubit_state(T, v) for (k, v) in final_state])
    yao2einsum(circuit, vec_initial_state, vec_final_state)
end
dict_regtype(d::Dict) = promote_type(_regtype.(values(d))...)
_regtype(::ArrayReg{D,VT}) where {D,VT} = VT
_regtype(::Int) = ComplexF64
render_single_qubit_state(::Type{T}, x::Int) where T = x == 0 ? zero_state(T, 1) : product_state(T, bit"1")
render_single_qubit_state(::Type{T}, x::ArrayReg) where T = ArrayReg(collect(T, statevec(x)))

function yao2einsum(circuit::AbstractBlock{D}, initial_state::Dict{Int,<:ArrayReg{D,T}}, final_state::Dict{Int,<:ArrayReg{D,T}}) where {D,T}
    n = nqubits(circuit)
    eb = EinBuilder(T, n)
    openindices = Int[]
    for k=1:n
        if haskey(initial_state, k)
            add_tensor!(eb, statevec(initial_state[k]), [eb.slots[k]])
        else
            push!(openindices, eb.slots[k])
        end
    end
    add_gate!(eb, circuit)
    openindices2 = Int[]
    for k=1:n
        if haskey(final_state, k)
            add_tensor!(eb, statevec(final_state[k]), [eb.slots[k]])
        else
            push!(openindices2, eb.slots[k])
        end
    end
    return build_einsum(eb, vcat(openindices2, openindices))
end

function build_einsum(eb::EinBuilder, openindices)
    return EinCode(eb.labels, openindices), eb.tensors
end

end
