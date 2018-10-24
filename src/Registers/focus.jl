#############################################
#            focus! and relax!
##############################################
"""
    oneto({reg::DefaultRegister}, n::Int=nqubits(reg)) -> DefaultRegister

Return a register with first 1:n bits activated, `reg` here can be lazy.
"""
function oneto(reg::DefaultRegister{B}, n::Int=nqubits(reg)) where B
    register(reshape(reg.state, 1<<n, :), B=B)
end
oneto(n::Int) = reg->oneto(reg, n)

"""
    relax!(reg::DefaultRegister; nbit::Int=nqubits(reg)) -> DefaultRegister
    relax!(reg::DefaultRegister, bits::Ints; nbit::Int=nqubits(reg)) -> DefaultRegister
    relax!(bits::Ints...; nbit::Int=-1) -> Function

Inverse transformation of focus, with nbit is the number of active bits of target register.
"""
function relax! end

"""
    focus!(reg::DefaultRegister, bits::Ints) -> DefaultRegister
    focus!(locs::Int...) -> Function

Focus register on specified active bits.
"""
function focus! end

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
    reg.state = reshape(arr, 1<<length(bits), :)
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
    focus!(func, reg::DefaultRegister, locs) -> DefaultRegister
"""
function focus!(func, reg::DefaultRegister, locs)
    nbit = nqubits(reg)
    relax!(func(reg |> focus!(locs...)), locs, nbit=nbit)
end
