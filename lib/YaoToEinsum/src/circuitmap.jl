# T is the element type of the tensor network
# D is the dimension of the qudits
# Key Interfaces:
# - Lowest level:
#   - `push_normal_tensor!(eb::EinBuilder, tensor::AbstractArray{T,N}, labels::Vector{Int})`, push a normal tensor data and its dual
#   - `trace!(eb::EinBuilder, group1::Vector{Int}, group2::Vector{Int})`, trace out indices
# - Middle level:
#   - `add_gate_matrix!(eb::EinBuilder, m::AbstractMatrix, locs::Vector)`, add a normal gate
#   - `add_controlled_matrix!(eb::EinBuilder, k::Int, m::AbstractMatrix, locs::Vector, control_locs, control_vals)`, add a controlled gate
#   - `add_channel!(eb::EinBuilder, b::SuperOp, locs::Vector)`, add a quantum channel
#   - `add_density_matrix!(eb::EinBuilder, density_matrix::DensityMatrix{D, T}, locs::Vector{Int}; conjugate::Bool)`, add a density matrix
# - Highest level (Yao block as inputs):
#   - `eat_observable!(eb::EinBuilder, b::AbstractBlock)`, add an observable
#   - `eat_gate!(eb::EinBuilder, b::AbstractBlock)`, add a quantum gate, with Yao Block as input
#   - `eat_states!(eb::EinBuilder, states::Dict; conjugate::Bool)`, add quantum states, ArrayReg or DensityMatrix as input
struct EinBuilder{MODE<:AbstractMappingMode, T, D}
    mode::MODE                         # the mapping mode, which can be `DensityMatrixMode()`, `PauliBasisMode()`, or `VectorMode()`
    slots::Vector{Int}                 # the labels for the open indices
    labels::Vector{Vector{Int}}        # tensor labels
    tensors::Vector{AbstractArray{T}}  # tensor data, the order is the same as the labels
    maxlabel::Base.RefValue{Int}       # the maximum label used
    label_to_qubit::Dict{Int, Int}     # map from variable label to qubit index (negative for dual, absent for non-qubit)
end
function EinBuilder{MODE, T, D}(mode::MODE, n::Int) where {MODE<:AbstractMappingMode, T, D}
    EinBuilder{MODE, T, D}(mode, collect(1:n), Vector{Int}[], AbstractArray{T}[], Ref(n), Dict(zip(1:n, 1:n)))
end
YaoBlocks.nqubits(eb::EinBuilder) = length(eb.slots)
function update_slots!(eb::EinBuilder, indices::Vector{Int}, labels::Vector{Int})
    for (l, i) in zip(labels, indices)
        eb.slots[i] = l
        eb.label_to_qubit[l] = i
    end
end

# add a normal tensor (like a normal quantum gate), if in density matrix mode or pauli basis mode, also add a dual tensor
# the dual tensor has conjugate elements, and the labels are negated
function push_normal_tensor!(eb::EinBuilder{MODE, T, D}, tensor::AbstractArray{T,N}, labels::Vector{Int}) where {MODE<:AbstractMappingMode, T, D, N}
    @assert N == length(labels)
    push!(eb.tensors, tensor)
    push!(eb.labels, labels)
    if eb.mode isa DensityMatrixMode || eb.mode isa PauliBasisMode
        push!(eb.tensors, conj(tensor))
        push!(eb.labels, (-).(labels))
    end
end

# connect right most line with its dual, often used in density matrix mode.
function trace!(eb::EinBuilder{DensityMatrixMode, T, D}, group1::Vector{Int}, group2::Vector{Int}) where {T, D}
    @assert length(group1) == length(group2) "group1 and group2 must have the same length"
    replacement = [group1[i] => group2[i] for i = 1:length(group1)]
    for i = 1:length(eb.labels)
        eb.labels[i] = replace(eb.labels[i], replacement...)
    end
    return eb
end
function trace!(eb::EinBuilder{PauliBasisMode, T, D}, group1::Vector{Int}, group2::Vector{Int}) where {T, D}
    @assert length(group1) == length(group2) "group1 and group2 must have the same length"
    traced = group1 ∪ group2
    # trace in pauli basis is equivalent to adding an identity operator, identity is equivalent to [sqrt(2), 0, 0, 0] in Pauli basis
    for i = 1:length(eb.labels)
        label = eb.labels[i]
        indices = [li ∈ traced ? 1 : Colon() for li in label]
        eb.labels[i] = filter(x->x ∉ traced, label)
        eb.tensors[i] = eb.tensors[i][indices...] .* 2^((length(label) - length(eb.labels[i]))/4)
    end
    return eb
end

# request a new label, increment the maxlabel
newlabel!(eb::EinBuilder) = (eb.maxlabel[] += 1; eb.maxlabel[])

# general and diagonal gates
# - `k` is the number of qubits that the gate acts on
# - `m` is the matrix of the gate
# - `locs` is the location of the qubits that the gate acts on
function add_gate_matrix!(eb::EinBuilder{MODE, T, D}, m::AbstractMatrix, locs::Vector) where {MODE<:AbstractMappingMode, T, D}
    if MODE <: PauliBasisMode  # Pauli basis mode must go to the channel!
        add_channel!(eb, SuperOp(matblock(m)), locs)
        return eb
    end

    k = length(locs)
    if isdiag(m)  # use isdiag, sometimes, the matrix is not a Diagonal, but isdiag(m) is true
        push_normal_tensor!(eb, reshape(Vector{T}(diag(m)), fill(D, k)...), eb.slots[locs])
    elseif m isa YaoBlocks.OuterProduct  # low rank
        nlabels = [newlabel!(eb) for _=1:k]
        K = rank(m)
        if K == 1  # projector
            push_normal_tensor!(eb, reshape(Vector{T}(m.right), fill(D, k)...), [eb.slots[locs]...])
            push_normal_tensor!(eb, reshape(Vector{T}(m.left), fill(D, k)...), [nlabels...])
            update_slots!(eb, locs, nlabels)
        else
            midlabel = newlabel!(eb)
            push_normal_tensor!(eb, reshape(Matrix{T}(m.right), fill(D, k)..., K), [eb.slots[locs]..., midlabel])
            push_normal_tensor!(eb, reshape(Matrix{T}(m.left), fill(D, k)..., K), [nlabels..., midlabel])
            update_slots!(eb, locs, nlabels)
        end
    else
        nlabels = [newlabel!(eb) for _=1:k]
        push_normal_tensor!(eb, reshape(Matrix{T}(m), fill(D, 2k)...), [nlabels..., eb.slots[locs]...])
        update_slots!(eb, locs, nlabels)
    end
    return eb
end

# add a gate to the einbuilder
function eat_gate!(eb::EinBuilder{MODE, T, D}, b::PutBlock{D,C}) where {MODE<:AbstractMappingMode, T,D,C}
    if isnoisy(b.content) || MODE isa PauliBasisMode
        # add the channel to the einbuilder, the mapping mode must be density matrix mode or pauli basis mode
        # since the Pauli basis mode mixes the label and its dual, we need to add the channel to the einbuilder instead of a normal gate.
        add_channel!(eb, SuperOp(b.content), collect(b.locs))
    else
        # add the matrix to the einbuilder
        add_gate_matrix!(eb, mat(T, b.content), collect(b.locs))
    end
    return eb
end

# swap gate
function eat_gate!(eb::EinBuilder{MODE, T, 2}, b::PutBlock{2,2,ConstGate.SWAPGate}) where {MODE<:AbstractMappingMode, T}
    MODE <: PauliBasisMode && error("Pauli basis mode does not support swap gate")
    lj = eb.slots[b.locs[2]]
    eb.slots[b.locs[2]] = eb.slots[b.locs[1]]
    eb.slots[b.locs[1]] = lj
    return eb
end

# projection gate, todo: generalize to arbitrary low rank gate
function eat_gate!(eb::EinBuilder{MODE, T, 2}, b::PutBlock{2,1,ConstGate.P0Gate}) where {MODE<:AbstractMappingMode, T}
    add_gate_matrix!(eb, YaoBlocks.OuterProduct(T[1, 0], T[1, 0]), collect(b.locs))
    return eb
end

# projection gate, todo: generalize to arbitrary low rank gate
function eat_gate!(eb::EinBuilder{MODE, T, 2}, b::PutBlock{2,1,ConstGate.P1Gate}) where {MODE<:AbstractMappingMode, T}
    add_gate_matrix!(eb, YaoBlocks.OuterProduct(T[0, 1], T[0, 1]), collect(b.locs))
    return eb
end


# control gates
function eat_gate!(eb::EinBuilder{MODE, T, 2}, b::ControlBlock{BT,C,M}) where {MODE<:AbstractMappingMode, T, BT,C,M}
    @assert !isnoisy(b.content) "Control gate is not supported for noisy channels! got: $b"
    MODE <: PauliBasisMode && return eat_gate!(eb, _putblock(b))
    return add_controlled_matrix!(eb, M, mat(T, b.content), collect(b.locs), collect(b.ctrl_locs), collect(b.ctrl_config))
end
function _putblock(b::ControlBlock)
    nc, nt = length(b.ctrl_locs), length(b.locs)
    gate = ControlBlock(nc+nt, ntuple(identity, nc), b.ctrl_config, b.content, ntuple(i->i+nc, nt))
    return put(b.n, (b.ctrl_locs..., b.locs...)=>gate)
end

function add_controlled_matrix!(eb::EinBuilder{MODE, T, 2}, k::Int, m::AbstractMatrix, locs::Vector, control_locs, control_vals) where {MODE<:AbstractMappingMode, T}
    if length(control_locs) == 0
        return add_gate_matrix!(eb, m, locs)
    end
    sig = eb.slots[control_locs[1]]
    val = control_vals[1]
    for i=1:length(control_locs)-1
        newsig = newlabel!(eb)
        push_normal_tensor!(eb, and_gate(T, control_vals[i+1], val), [newsig,eb.slots[control_locs[i+1]],sig])
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
        push_normal_tensor!(eb, cat(t1, t2; dims=2k+1), [nlabels..., eb.slots[locs]..., sig])
        update_slots!(eb, locs, nlabels)
    else
        t1 = reshape(Vector{T}(diag(m)), fill(2, k)...)
        t2 = reshape(ones(T, 1<<k), fill(2, k)...)
        if val == 1
            t1, t2 = t2, t1
        end
        push_normal_tensor!(eb, cat(t1, t2; dims=k+1), [eb.slots[locs]..., sig])
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

function eat_gate!(eb::EinBuilder{MODE, T, D}, b::ChainBlock) where {MODE<:AbstractMappingMode, T, D}
    for ib in subblocks(b)
        eat_gate!(eb, ib)
    end
    return eb
end

# try simplify and convert
function eat_gate!(eb::EinBuilder, b::AbstractBlock)
    B = Optimise.to_basictypes(b)
    if typeof(B) == typeof(b)
        throw("block of type `$(typeof(b))` can not be converted to tensor network representation!")
    else
        eat_gate!(eb, B)
    end
    return eb
end

# matblock
function eat_gate!(eb::EinBuilder{MODE, T, D}, b::GeneralMatrixBlock) where {MODE<:AbstractMappingMode, T, D}
    add_gate_matrix!(eb, mat(T, b), collect(1:nqubits(b)))
    return eb
end

# Channels
for CT in [:KrausChannel, :DepolarizingChannel, :MixedUnitaryChannel, :SuperOp]
    @eval function eat_gate!(eb::EinBuilder{MODE, T, D}, b::$CT) where {MODE<:Union{DensityMatrixMode, PauliBasisMode}, T, D}
        add_channel!(eb, SuperOp(b), collect(1:nqubits(b)))
        return eb
    end
end

# add a quantum channel, which is a superoperator
function add_channel!(eb::EinBuilder{MODE, T, D}, b::SuperOp, locs::Vector{Int}) where {MODE<:Union{DensityMatrixMode, PauliBasisMode}, T, D}
    MODE <: PauliBasisMode && (b = to_pauli_basis(b))

    mat = Matrix{T}(b.superop)
    k = length(locs)
    nlabels = [newlabel!(eb) for _=1:k]
    push!(eb.tensors, reshape(mat, fill(D, 4k)...))
    push!(eb.labels, [nlabels..., (-).(nlabels)..., eb.slots[locs]..., (-).(eb.slots[locs])...])
    update_slots!(eb, locs, nlabels)
    return eb
end

# add a density matrix at location `locs`
function add_density_matrix!(eb::EinBuilder{MODE, T, D}, density_matrix::DensityMatrix{D, T}, locs::Vector{Int}; conjugate::Bool) where {MODE<:Union{DensityMatrixMode, PauliBasisMode}, T, D}
    density_matrix = MODE <: PauliBasisMode ? to_pauli_basis(density_matrix) : density_matrix
    conjugate && (density_matrix = DensityMatrix{D}(conj.(density_matrix.state)))
    k = length(locs)
    push!(eb.tensors, reshape(density_matrix.state, fill(D, 2k)...))
    push!(eb.labels, [eb.slots[locs]..., (-).(eb.slots[locs])...])
    return eb
end

# Add observable: apply the observable to the final state, and trace with the dual indices, i.e. performing `tr(rho, operator)`
function eat_observable!(eb::EinBuilder{MODE, T, D}, b::AbstractBlock) where {MODE<:DensityMatrixMode, T, D}
    # Note: the observable is only added once to the network, hence we need to use the vector mode to add it
    eb_vec = EinBuilder{VectorMode, T, D}(VectorMode(), eb.slots, eb.labels, eb.tensors, eb.maxlabel, eb.label_to_qubit)
    group1 = (-).(eb.slots)
    eat_gate!(eb_vec, b)
    trace!(eb, group1, eb.slots)
    return eb
end

function eat_observable!(eb::EinBuilder{MODE, T, D}, b::AbstractBlock) where {MODE<:PauliBasisMode, T, D}
    @assert b isa Union{KronBlock, PutBlock, RepeatedBlock} "Pauli basis mode only supports observable of the form `kron(2=>X, 3=>X)` or `put(2, 1=>X)` or `repeat(2, X)`, i.e. kron of operators on different qubits. Got: $b"
    b = _to_kron(b)
    openindices = eat_states!(eb, Dict([collect(Int, locs)=>DensityMatrix{D}(conj.(Matrix{T}(op))) for (locs, op) in zip(b.locs, b.blocks)]); conjugate=true)
    no = length(openindices) ÷ 2
    !iszero(no) && trace!(eb, openindices[1:no], openindices[no+1:end])
    return eb
end
_to_kron(x::KronBlock) = x
_to_kron(x::PutBlock) = kron(x.n, x.locs=>x.content)
_to_kron(x::RepeatedBlock) = kron(x.n, [i=>x.content for i=x.locs]...)

function eat_states!(eb::EinBuilder{MODE, T, D}, states::Dict; conjugate::Bool) where {MODE<:AbstractMappingMode, T, D}
    # check the state specification
    n = nqubits(eb)
    iks = collect(Int, vcat(keys(states)...))
    @assert length(unique(iks)) == length(iks) "state qubit indices must be unique"
    @assert all(1 .<= iks .<= n) "state qubit indices must be in the range 1 to $n"
    openindices = eb.slots[setdiff(1:n, iks)]

    for (k, state) in states
        if MODE <: PauliBasisMode && state isa ArrayReg  # convert to density matrix
            state = density_matrix(state)
        end
        if state isa DensityMatrix
            add_density_matrix!(eb, state, k; conjugate)
        else
            push_normal_tensor!(eb, (conjugate ? conj : identity).(dropdims(hypercubic(state); dims=length(k)+1)), eb.slots[k])
        end
    end
    return MODE <: Union{DensityMatrixMode, PauliBasisMode} ? Int[openindices..., (-).(openindices)...] : openindices
end

"""
    yao2einsum(circuit; initial_state=Dict(), final_state=Dict(), optimizer=TreeSA(), mode=VectorMode(), observable=nothing, slicer=nothing)

Transform a Yao `circuit` to a generalized tensor network (einsum) notation.
The return value is a [`TensorNetwork`](@ref) instance that corresponds to the following tensor network:

1). If mode is `VectorMode()`, the tensor network will be like:
```
<initial_state| ─── circuit ─── |final_state>
```

2). If the mode is `DensityMatrixMode()`, the tensor network will be like:
```
<final_state| ─── circuit ─── |initial_state><initial_state| ─── circuit ─── |final_state>
```
where the `circuit` may contain noise channels.

3). In the `DensityMatrixMode()`, if `observable` is specified, compute `tr(rho, observable)` instead.
```
┌── circuit ─── |initial_state><initial_state| ─── circuit ─── observable ──┐
└───────────────────────────────────────────────────────────────────────────┘
```

4). `PauliBasisMode()` is similar to the `DensityMatrixMode()` mode, but the basis will be rotated to the Pauli basis.

### Arguments
- `mode` is the mapping mode, which can be `DensityMatrixMode()`, `PauliBasisMode()`, or `VectorMode()`.
- `circuit` is a Yao block as the input.
- `initial_state` and `final_state` are dictionaries to specify the initial states and final states (taking conjugate).
    - In the first interface, a state is specified as an integer, e.g. `Dict(1=>1, 2=>1, 3=>0, 4=>1)` specifies a product state `|1⟩⊗|1⟩⊗|0⟩⊗|1⟩`.
    - In the second interface, a state is specified as an `ArrayReg`, e.g. `Dict(1=>rand_state(1), 2=>rand_state(1))`.
- `observable` is a Yao block to specify the observable. If it is specified, the final state must be unspecified.
If any qubit in initial state or final state is not specified, it will be treated as a free leg in the tensor network.
- `optimizer` is the optimizer used to optimize the tensor network. The default is `TreeSA()`.
- `slicer` is the slicer used to slice the tensor network and reduce the memory usage, e.g. to reduce the largest tensor rank to 30, use `TreeSASlicer(score=OMEinsum.ScoreFunction(sc_target=30))`.
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
function yao2einsum(circuit::AbstractBlock{D}; mode::AbstractMappingMode=VectorMode(), initial_state::Dict=Dict{Int,Int}(), final_state::Dict=Dict{Int,Int}(), observable=nothing, optimizer=TreeSA(), slicer=nothing) where {D}
    @assert isempty(final_state) || isnothing(observable) "Please do not specify both `final_state` and `observable`, got final_state=$final_state and observable=$observable"
    @assert (mode isa DensityMatrixMode || mode isa PauliBasisMode) || isnothing(observable) "If you want to compute the expectation value of an observable, please use `DensityMatrixMode()`"
    T = promote_type(ComplexF64, dict_regtype(initial_state), dict_regtype(final_state), YaoBlocks.parameters_eltype(circuit))

    n = nqudits(circuit)
    eb = EinBuilder{typeof(mode), T, D}(mode, n)

    # add the initial state
    initial_state = Dict([[k...]=>render_single_qudit_state(T, D, v) for (k, v) in initial_state])
    openindices = eat_states!(eb, initial_state; conjugate=false)
    # add the circuit
    eat_gate!(eb, circuit)
    # add the final state or observable
    if !isnothing(observable)
        eat_observable!(eb, observable)
    elseif !isempty(final_state)
        final_state = Dict([[k...]=>render_single_qudit_state(T, D, v) for (k, v) in final_state])
        openindices2 = eat_states!(eb, final_state; conjugate=true)
        openindices = vcat(openindices2, openindices)
    else
        openindices2 = mode isa Union{DensityMatrixMode, PauliBasisMode} ? Int[eb.slots..., (-).(eb.slots)...] : eb.slots
        openindices = vcat(openindices2, openindices)
    end

    # construct the tensor network
    network = build_einsum(eb, openindices)
    return optimizer === nothing ? network : optimize_code(network, optimizer; simplifier=MergeVectors(), slicer)
end
dict_regtype(d::Dict) = promote_type(_regtype.(values(d))...)
_regtype(::ArrayReg{D,VT}) where {D,VT} = VT
_regtype(::DensityMatrix{D,VT}) where {D,VT} = VT
_regtype(::Int) = ComplexF64
render_single_qudit_state(::Type{T}, D, x::Int) where T = product_state(T, DitStr{D}([x]))
render_single_qudit_state(::Type{T}, D, x::ArrayReg) where T = ArrayReg{D}(collect(T, statevec(x)))
render_single_qudit_state(::Type{T}, D, x::DensityMatrix) where {T} = DensityMatrix{D}(Matrix{T}(x.state))

function build_einsum(eb::EinBuilder, openindices::Vector{Int})
    return TensorNetwork(EinCode(eb.labels, openindices), eb.tensors, eb.label_to_qubit)
end

