#############################################
#            focus! and relax!
##############################################
"""
Get the compact shape and order for permutedims.
"""
function shapeorder(shape::NTuple, order::Vector{Int})
    nshape = Int[]
    norder = Int[]
    k_pre = -1
    for k in order
        if k == k_pre+1
            nshape[end] *= shape[k]
        else
            push!(norder, k)
            push!(nshape, shape[k])
        end
        k_pre = k
    end
    invorder = norder |> sortperm
    nshape[invorder], invorder |> invperm
end

move_ahead(collection, head)::Vector{Int} = vcat(head..., setdiff(collection, head))
move_ahead(ndim::Int, head)::Vector{Int} = vcat(head..., setdiff(1:ndim, head))

function group_permutedims(arr::AbstractArray, order::Vector{Int})
    nshape, norder = shapeorder(size(arr), order)
    permutedims(reshape(arr, nshape...), norder)
end

function focus!(reg::DefaultRegister{B}, bits) where B
    nbit = nactive(reg)
    if all(bits .== 1:length(bits))
        arr = reg.state
    else
        norder = move_ahead(nbit+1, bits)
        arr = group_permutedims(reg |> hypercubic, norder)
    end
    reg.state = reshape(arr, :, (1<<(nbit-length(bits)))*B)
    reg
end

function relax!(reg::DefaultRegister{B}, bits; nbit::Int=nqubits(reg)) where B
    reg.state = reshape(reg.state, 1<<nbit, :)
    if any(bits .!= 1:length(bits))
        norder = move_ahead(nbit+1, bits) |> invperm
        reg.state = reshape(group_permutedims(reg |> hypercubic, norder), 1<<nbit, :)
    end
    reg
end

relax!(reg::DefaultRegister; nbit::Int=nqubits(reg)) = relax!(reg, Int[], nbit=nbit)

focus!(locs::Int...) = r->focus!(r, locs)
relax!(locs::Int...; nbit::Int=-1) = r->relax!(r, locs, nbit=nbit>0 ? nbit : nqubits(r))

"""
    focuspair(locs::Int...) -> NTuple{2, Function}

Return focus! and relax! function for specific lines.
"""
function focuspair!(locs::Int...)
    local nbit::Int
    f1 = r->(nbit = nqubits(r); focus!(r, locs))
    f1, r->relax!(r, locs, nbit=nbit)
end

"""
    Focus{N} <: AbatractBlock

Focus manager, with N the number of qubits.
"""
struct Focus{N}
    address::Vector{Int}
    Focus{N}() where N = new{N}(collect(1:N))
end
(f::Focus)(bits::Int...) = (f.address[:] = move_ahead(f.address, bits);focus!(bits...))
function (f::Focus{N})(::Void) where N
    func = relax!(f.address...)
    f.address[:] = 1:N
    func
end

Focus(N::Int) = Focus{N}()
