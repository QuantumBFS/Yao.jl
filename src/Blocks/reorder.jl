reorder(A::IMatrix, orders) = A
function reorder(A::PermMatrix, orders::Vector{Int})
    M = size(A, 1)
    nbit = M|>log2i
    od::Vector{Int} = [b+1 for b::Int in reordered_basis(nbit, orders)]
    perm = similar(A.perm)
    vals = similar(A.vals)
    @simd for i = 1:length(perm)
        @inbounds perm[od[i]] = od[A.perm[i]]
        @inbounds vals[od[i]] = A.vals[i]
    end
    PermMatrix(perm, vals)
end

function reorder(A::Diagonal, orders::Vector{Int})
    M = size(A, 1)
    nbit = M|>log2i
    #od::Vector{Int} = [b+1 for b::Int in reordered_basis(nbit, orders)]
    diag = similar(A.diag)
    #for i = 1:length(perm)
    #    diag[od[i]] = A.diag[i]
    #end
    i = 1
    for b::Int in reordered_basis(nbit, orders)
        diag[b+1] = A.diag[i]
        i += 1
    end
    Diagonal(diag)
end
