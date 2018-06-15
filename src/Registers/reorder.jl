import ..Intrinsics: _reorder
function reorder(v::AbstractVector, orders)
    nbit = length(orders)
    nbit == length(v) |> log2i || throw(DimensionMismatch("size of array not match length of order"))
    nv = similar(v)
    taker, differ = bmask.(orders), (1:nbit).-orders

    for b in basis(nbit)
        @inbounds nv[b+1] = v[_reorder(b, taker, differ)+1]
    end
    nv
end

function reorder(A::Union{Matrix, SparseMatrixCSC}, orders)
    M, N = size(A)
    nbit = M|>log2i
    od = [1+b for b in reordered_basis(nbit, orders)]
    od = od |> invperm
    A[od, od]
end

function reorder!(reg::DefaultRegister, orders)
    for i in size(reg.state, 2)
        reg.state[:,i] = reorder(reg.state[:, i], orders)
    end
    reg
end

invorder!(reg::DefaultRegister) = reorder!(reg, nqubits(reg):-1:1)
