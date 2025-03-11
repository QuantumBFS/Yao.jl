# T is the element type of the tensor network
# D is the dimension of the qudits
struct EinBuilder{T, D}
    slots::Vector{Int}
    labels::Vector{Vector{Int}}
    tensors::Vector{AbstractArray{T}}
    maxlabel::Base.RefValue{Int}
end

YaoBlocks.nqubits(eb::EinBuilder) = length(eb.slots)
function add_tensor!(eb::EinBuilder{T}, tensor::AbstractArray{T,N}, labels::Vector{Int}) where {N,T}
    @assert N == length(labels)
    push!(eb.tensors, tensor)
    push!(eb.labels, labels)
end

function EinBuilder{T, D}(n::Int) where {T, D}
    EinBuilder{T, D}(collect(1:n), Vector{Int}[], AbstractArray{T}[], Ref(n))
end
newlabel!(eb::EinBuilder) = (eb.maxlabel[] += 1; eb.maxlabel[])

function add_gate!(eb::EinBuilder{T}, b::PutBlock{D,C}) where {T,D,C}
    return add_matrix!(eb, C, mat(T, b.content), collect(b.locs))
end
# general and diagonal gates
function add_matrix!(eb::EinBuilder{T, D}, k::Int, m::AbstractMatrix, locs::Vector) where {T, D}
    if m isa Diagonal
        add_tensor!(eb, reshape(Vector{T}(diag(m)), fill(D, k)...), eb.slots[locs])
    elseif m isa YaoBlocks.OuterProduct  # low rank
        nlabels = [newlabel!(eb) for _=1:k]
        K = rank(m)
        if K == 1  # projector
            add_tensor!(eb, reshape(Vector{T}(m.right), fill(D, k)...), [eb.slots[locs]...])
            add_tensor!(eb, reshape(Vector{T}(m.left), fill(D, k)...), [nlabels...])
            eb.slots[locs] .= nlabels
        else
            midlabel = newlabel!(eb)
            add_tensor!(eb, reshape(Matrix{T}(m.right), fill(D, k)..., K), [eb.slots[locs]..., midlabel])
            add_tensor!(eb, reshape(Matrix{T}(m.left), fill(D, k)..., K), [nlabels..., midlabel])
            eb.slots[locs] .= nlabels
        end
    else
        nlabels = [newlabel!(eb) for _=1:k]
        add_tensor!(eb, reshape(Matrix{T}(m), fill(D, 2k)...), [nlabels..., eb.slots[locs]...])
        eb.slots[locs] .= nlabels
    end
    return eb
end
# swap gate
function add_gate!(eb::EinBuilder{T, 2}, b::PutBlock{2,2,ConstGate.SWAPGate}) where {T}
    lj = eb.slots[b.locs[2]]
    eb.slots[b.locs[2]] = eb.slots[b.locs[1]]
    eb.slots[b.locs[1]] = lj
    return eb
end

# projection gate, todo: generalize to arbitrary low rank gate
function add_gate!(eb::EinBuilder{T, 2}, b::PutBlock{2,1,ConstGate.P0Gate}) where {T}
    add_matrix!(eb, 1, YaoBlocks.OuterProduct(T[1, 0], T[1, 0]), collect(b.locs))
    return eb
end

# projection gate, todo: generalize to arbitrary low rank gate
function add_gate!(eb::EinBuilder{T, 2}, b::PutBlock{2,1,ConstGate.P1Gate}) where {T}
    add_matrix!(eb, 1, YaoBlocks.OuterProduct(T[0, 1], T[0, 1]), collect(b.locs))
    return eb
end


# control gates
function add_gate!(eb::EinBuilder{T, 2}, b::ControlBlock{BT,C,M}) where {T, BT,C,M}
    return add_controlled_matrix!(eb, M, mat(T, b.content), collect(b.locs), collect(b.ctrl_locs), collect(b.ctrl_config))
end
function add_controlled_matrix!(eb::EinBuilder{T, 2}, k::Int, m::AbstractMatrix, locs::Vector, control_locs, control_vals) where T
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
    yao2einsum(circuit; initial_state=Dict(), final_state=Dict(), optimizer=TreeSA())
    yao2einsum(circuit, initial_state::Dict, final_state::Dict, optimizer)

Transform a Yao `circuit` to a generalized tensor network (einsum) notation.
The return value is a [`TensorNetwork`](@ref) instance.

### Arguments
* `circuit` is a Yao block as the input.
* `initial_state` and `final_state` are dictionaries to specify the initial states and final states (taking conjugate).
    - In the first interface, a state is specified as an integer, e.g. `Dict(1=>1, 2=>1, 3=>0, 4=>1)` specifies a product state `|1⟩⊗|1⟩⊗|0⟩⊗|1⟩`.
    - In the second interface, a state is specified as an `ArrayReg`, e.g. `Dict(1=>rand_state(1), 2=>rand_state(1))`.
If any qubit in initial state or final state is not specified, it will be treated as a free leg in the tensor network.
* `optimizer` is the optimizer used to optimize the tensor network. The default is `TreeSA()`.
Please check [OMEinsumContractors.jl](https://github.com/TensorBFS/OMEinsumContractionOrders.jl) for more information.


```jldoctest
julia> using Yao

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
TensorNetwork
Time complexity: 2^4.700439718141093
Space complexity: 2^2.0
Read-write complexity: 2^6.0
```
"""
function yao2einsum(circuit::AbstractBlock{D}; initial_state::Dict=Dict{Int,Int}(), final_state::Dict=Dict{Int,Int}(), optimizer=TreeSA()) where {D}
    T = promote_type(ComplexF64, dict_regtype(initial_state), dict_regtype(final_state), YaoBlocks.parameters_eltype(circuit))
    vec_initial_state = Dict{keytype(initial_state),ArrayReg{D,T}}([k=>render_single_qudit_state(T, D, v) for (k, v) in initial_state])
    vec_final_state = Dict{keytype(final_state),ArrayReg{D,T}}([k=>render_single_qudit_state(T, D, v) for (k, v) in final_state])
    yao2einsum(circuit, vec_initial_state, vec_final_state, optimizer)
end
dict_regtype(d::Dict) = promote_type(_regtype.(values(d))...)
_regtype(::ArrayReg{D,VT}) where {D,VT} = VT
_regtype(::Int) = ComplexF64
render_single_qudit_state(::Type{T}, D, x::Int) where T = product_state(T, DitStr{D}([x]))
render_single_qudit_state(::Type{T}, D, x::ArrayReg) where T = ArrayReg{D}(collect(T, statevec(x)))

function yao2einsum(circuit::AbstractBlock{D}, initial_state::Dict{Int,<:ArrayReg{D,T}}, final_state::Dict{Int,<:ArrayReg{D,T}}, optimizer) where {D,T}
    v_initial_state = Dict{Vector{Int}, ArrayReg{D,T}}([[k]=>v for (k, v) in initial_state])
    v_final_state = Dict{Vector{Int}, ArrayReg{D, T}}([[k]=>v for (k, v) in final_state])
    yao2einsum(circuit, v_initial_state, v_final_state, optimizer)
end
function yao2einsum(circuit::AbstractBlock{D}, initial_state::Dict{Vector{Int},<:ArrayReg{D,T}}, final_state::Dict{Vector{Int},<:ArrayReg{D,T}}, optimizer) where {D,T}
    n = nqudits(circuit)
    eb = EinBuilder{T, D}(n)
    openindices = add_states!(eb, initial_state)
    add_gate!(eb, circuit)
    openindices2 = add_states!(eb, final_state; conjugate=true)
    network = build_einsum(eb, vcat(openindices2, openindices))
    return optimizer === nothing ? network : optimize_code(network, optimizer, MergeVectors())
end
function check_state_spec(state::Dict{Vector{Int},<:ArrayReg{D,T}}, n::Int) where {D,T}
    iks = collect(Int, vcat(keys(state)...))
    @assert length(unique(iks)) == length(iks) "state qubit indices must be unique"
    @assert all(1 .<= iks .<= n) "state qubit indices must be in the range 1 to $n"
    return iks
end
function add_states!(eb::EinBuilder{T, D}, states::Dict; conjugate=false) where {T, D}
    n = nqubits(eb)
    unique_indices = check_state_spec(states, n)
    openindices = eb.slots[setdiff(1:n, unique_indices)]
    for (k, state) in states
        add_tensor!(eb, (conjugate ? conj : identity).(dropdims(hypercubic(state); dims=length(k)+1)), eb.slots[k])
    end
    return openindices
end

function build_einsum(eb::EinBuilder, openindices)
    return TensorNetwork(EinCode(eb.labels, openindices), eb.tensors)
end

