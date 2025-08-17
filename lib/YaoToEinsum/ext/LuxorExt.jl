module LuxorExt

using YaoToEinsum, LuxorGraphPlot, YaoToEinsum.OMEinsum, LuxorGraphPlot.Graphs

"""
    assign_coordinates(tn::TensorNetwork; dual_offset=[0.25, 0.25], dangling_offset=[-0.15, -0.15])

Assign coordinates to tensors (for visualization or sweep contractors).

# Arguments
- `tn`: the tensor network to assign coordinates to.

# Keyword Arguments
- `dual_offset`: the offset of the dual variables.
- `dangling_offset`: the offset of the dangling tensors (those only involve one variables).

# Returns
- `tensor_coos::Vector{Vector{Float64}}`: the coordinates of the tensors.
"""
function assign_coordinates(tn::TensorNetwork; dual_offset=[0.25, 0.25], dangling_offset=[-0.15, -0.15])
    n = maximum(values(tn.label_to_qubit))
    frontier = zeros(Int, n)
    # initialize coordinates
    label_to_coo = Dict{Int, Vector{Float64}}()
    for i=1:n
        label_to_coo[i] = [0.0, i]
        label_to_coo[-i] = [0.0, i] + dual_offset
    end

    tensor_coos = Vector{Float64}[]
    for (i, ix) in enumerate(OMEinsum.getixsv(tn.code))
        # update label coordinates
        qubits = [tn.label_to_qubit[abs(label)] for label in ix if haskey(tn.label_to_qubit, abs(label))]
        newfrontier = maximum(q->frontier[q], qubits) + 1
        frontier[minimum(qubits):maximum(qubits)] .= newfrontier
        for label in ix
            if !haskey(label_to_coo, label) && haskey(tn.label_to_qubit, abs(label))  # new physical qubit
                qubit = tn.label_to_qubit[abs(label)]
                label_to_coo[label] = [frontier[qubit], qubit]
                label_to_coo[-label] = label_to_coo[label] + dual_offset
            end
        end
        # update tensor coordinates
        coos = [label_to_coo[label] for label in ix if haskey(label_to_coo, label)]
        tcoo = sum(coos)/length(coos)
        # avoid crossing the line
        if (_isinteger(tcoo[2]) || _isinteger(tcoo[2] - dual_offset[2])) && round(Int, tcoo[2]) ∉ qubits
            tcoo[2] += 0.5
        end
        # avoid crossing the variable
        if length(coos) == 1
            tcoo += dangling_offset * sign(ix[1])
        end
        push!(tensor_coos, tcoo)
    end
    # decide the coordinates of virtual indices
    for label in uniquelabels(tn.code)
        if !haskey(label_to_coo, label)
            tensors = findall(ix -> label in ix, OMEinsum.getixsv(tn.code))
            coos = [tensor_coos[i] for i in tensors]
            label_to_coo[label] = sum(coos)/length(coos)
            label_to_coo[-label] = label_to_coo[label] + dual_offset
        end
    end
    return tensor_coos, label_to_coo
end
_isinteger(x) = x ≈ round(Int, x)

function YaoToEinsum.viznet(tn::TensorNetwork; scale=100, filename=nothing, dual_offset=[0.25, 0.25], dangling_offset=[-0.15, -0.15], node_size=7)
    labels = uniquelabels(tn.code)
    tensor_coos, label_to_coo = assign_coordinates(tn; dual_offset, dangling_offset)
    label_coos = [label_to_coo[label] for label in labels]

    # construct the bipartite graph
    graph = SimpleGraph(length(label_coos) + length(tensor_coos))  # the first batch of vertices are for labels
    label2idx = Dict(zip(labels, 1:length(labels)))
    ixs = OMEinsum.getixsv(tn.code)
    for (i, ix) in enumerate(ixs)
        for label in ix
            add_edge!(graph, label2idx[label], i + length(labels))
        end
    end

    locs = [Tuple(coo .* scale) for coo in vcat(label_coos, tensor_coos)]  # flip x-y axis
    vertex_shapes = [i <= length(labels) ? :circle : :circle for i in 1:length(locs)]  # box for variables
    vertex_colors = [i <= length(labels) ? (labels[i] > 0 ? "hotpink" : "lawngreen") : "transparent" for i in 1:length(locs)]
    vertex_stroke_colors = [i <= length(labels) ? "transparent" : "black" for i in 1:length(locs)]
    vertex_sizes = [i <= length(labels) ? 8 : (length(ixs[i-length(labels)]) == 1 ? 6 : node_size) for i in 1:length(locs)]
    texts = [i <= length(labels) ? string(labels[i]) : special_tensor_detection(tn.tensors[i-length(labels)]) for i in 1:length(locs)]
    gviz = GraphViz(graph, locs; texts, vertex_colors, vertex_stroke_colors, vertex_shapes, vertex_sizes)
    config = GraphDisplayConfig()
    return show_graph(gviz; filename, config)
end

function special_tensor_detection(t::AbstractArray)
    allequal(size(t)) || return ""
    if ndims(t) == 1 && length(t) == 2
        if t ≈ [1, 0]
            return "0"
        elseif t ≈ [0, 1]
            return "1"
        elseif t ≈ [1, 1]
            return "Σ"
        elseif t ≈ [1, 1]/sqrt(2)
            return "+"
        elseif t ≈ [1, -1]/sqrt(2)
            return "-"
        end
    end
    if ndims(t) == 2 && length(t) == 4
        if t ≈ [1 1; 1 -1]/sqrt(2)
            return "H"
        elseif t ≈ [1 1; 1 -1]
            return "h"
        elseif t ≈ [1 0; 0 1]
            return "I"
        elseif t ≈ [0 1; 1 0]
            return "X"
        elseif t ≈ [0 -1im; 1im 0]
            return "Y"
        elseif t ≈ [0 1im; -1im 0]
            return "Y*"
        elseif t ≈ [1 0; 0 -1]
            return "Z"
        elseif t ≈ [1 1; 1 1]
            return "Σ"
        elseif t ≈ [1 0; 0 0]
            return "P₀"
        elseif t ≈ [0 0; 0 1]
            return "P₁"
        elseif t ≈ [0 1; 0 0]
            return "P₊"
        elseif t ≈ [0 0; 1 0]
            return "P₋"
        end
    end
    if allequal(t)
        return "$(round(t[1], digits=2))"
    elseif isdelta(t)
        return "δ"
    elseif isxor(t)
        return "⊻"
    end
    return ""
end

function isdelta(t::AbstractArray{T, N}) where {T, N}
    !allequal(size(t)) && return false
    for ci in CartesianIndices(t)
        if allequal(ci.I)
            t[ci] == T(1) || return false
        else
            t[ci] == T(0) || return false
        end
    end
    return true
end

function isxor(t::AbstractArray{T, N}) where {T, N}
    !all(==(2), size(t)) && return false
    for ci in CartesianIndices(t)
        t[ci] == (iseven(count(==(2), ci.I)) ? T(1) : T(0)) || return false
    end
    return true
end

end