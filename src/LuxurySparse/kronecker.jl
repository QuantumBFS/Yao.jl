function irepeat(v::AbstractVector, n::Int)
    nV = length(v)
    res = similar(v, nV*n)
    @inbounds for j = 1:nV
        vj = v[j]
        base = (j-1)*n
        @inbounds @simd for i = 1:n
            res[base+i] = vj
        end
    end
    res
end

function orepeat(v::AbstractVector, n::Int)
    nV = length(v)
    res = similar(v, nV*n)
    @inbounds for i = 1:n
        base = (i-1)*nV
        @inbounds @simd for j = 1:nV
            res[base+j] = v[j]
        end
    end
    res
end


# TODO: since 0.7 transpose is different, we don't take transpose serious here.
####### kronecker product ###########
import Base: kron
# TODO: if Identity{1}, do nothing
kron(A::Identity{Na, Ta}, B::Identity{Nb, Tb}) where {Na, Nb, Ta, Tb}= Identity{Na*Nb, promote_type(Ta, Tb)}()
kron(A::Identity{Na}, B::Diagonal) where Na = Diagonal(orepeat(B.diag, Na))
kron(B::Diagonal, A::Identity{Na}) where Na = Diagonal(irepeat(B.diag, Na))
kron(A::Identity{1}, B::AbstractMatrix) = B

####### diagonal kron ########
kron(A::Diagonal, B::Diagonal) = Diagonal(kron(A.diag, B.diag))
kron(A::StridedMatrix, B::Diagonal) = kron(A, PermMatrix(B))
kron(A::Diagonal, B::StridedMatrix) = kron(PermMatrix(A), B)
kron(A::Diagonal, B::SparseMatrixCSC) = kron(PermMatrix(A), B)
kron(A::SparseMatrixCSC, B::Diagonal) = kron(A, PermMatrix(B))


function kron(A::AbstractMatrix{Tv}, B::Identity{Nb}) where {Nb, Tv}
    mA, nA = size(A)
    nzval = Vector{Tv}(Nb*mA*nA)
    rowval = Vector{Int}(Nb*mA*nA)
    colptr = collect(1:mA:Nb*mA*nA+1)
    @inbounds for j = 1:nA
        source = A[:,j]
        startbase = (j-1)*Nb*mA - mA
        @inbounds for j2 = 1:Nb
            start = startbase + j2*mA
            row = j2-Nb
            @inbounds @simd for i = 1:mA
                nzval[start+i] = source[i]
                rowval[start+i] = row+Nb*i
            end
        end
    end
    SparseMatrixCSC(mA*Nb, nA*Nb, colptr, rowval, nzval)
end

function kron(A::Identity{Na}, B::AbstractMatrix{Tv}) where {Na, Tv}
    mB, nB = size(B)
    rowval = Vector{Int}(nB*mB*Na)
    nzval = Vector{Tv}(nB*mB*Na)
    @inbounds for j in 1:Na
        r0 = (j-1)*mB
        @inbounds for j2 in 1:nB
            start = ((j-1)*nB+j2-1)*mB
            @inbounds @simd for i in 1:mB
                rowval[start+i] = r0+i
                nzval[start+i] = B[i,j2]
            end
        end
    end
    colptr = collect(1:mB:nB*mB*Na+1)
    SparseMatrixCSC(mB*Na, Na*nB, colptr, rowval, nzval)
end

function kron(A::Identity{Na}, B::SparseMatrixCSC{T}) where {Na, T}
    mB, nB = size(B)
    nV = nnz(B)
    nzval = Vector{T}(Na*nV)
    rowval = Vector{Int}(Na*nV)
    colptr = Vector{Int}(nB*Na+1)
    nzval = Vector{T}(Na*nV)
    colptr[1] = 1
    @inbounds for i = 1:Na
        r0 = (i-1)*mB
        start = nV*(i-1)
        @inbounds @simd for k = 1:nV
            rowval[start+k] = B.rowval[k]+r0
            nzval[start+k] = B.nzval[k]
        end
        colbase = (i-1)*nB
        @inbounds @simd for j=2:nB+1
            colptr[colbase+j] = B.colptr[j]+start
        end
    end
    SparseMatrixCSC(mB*Na, nB*Na, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::Identity{Nb}) where {T, Nb}
    mA, nA = size(A)
    nV = nnz(A)
    rowval = Vector{Int}(Nb*nV)
    colptr = Vector{Int}(nA*Nb+1)
    nzval = Vector{T}(Nb*nV)
    z=1
    colptr[1] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        colbase = (i-1)*Nb+1
        @inbounds for k in 1:Nb
            irow_Nb = k - Nb
            @inbounds @simd for r in rstart:rend
                rowval[z] = A.rowval[r]*Nb+irow_Nb
                nzval[z] = A.nzval[r]
                z+=1
            end
            colptr[colbase+k] = z
        end
    end
    SparseMatrixCSC(mA*Nb, nA*Nb, colptr, rowval, nzval)
end

function kron(A::PermMatrix{T}, B::Identity) where T
    nA = size(A, 1)
    nB = size(B, 1)
    vals = Vector{T}(nB*nA)
    perm = Vector{Int}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        permAi = (A.perm[i]-1)*nB
        val = A.vals[i]
        @inbounds @simd for j = 1:nB
            perm[start+j] = permAi + j
            vals[start+j] = val
        end
    end
    PermMatrix(perm, vals)
end

function kron(A::Identity, B::PermMatrix{T}) where T
    nA = size(A, 1)
    nB = size(B, 1)
    perm = Vector{Int}(nB*nA)
    vals = Vector{T}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        @inbounds @simd for j = 1:nB
            perm[start+j] = start +B.perm[j]
            vals[start+j] = B.vals[j]
        end
    end
    PermMatrix(perm, vals)
end


function kron(A::StridedMatrix{Tv}, B::PermMatrix{Tb}) where {Tv, Tb}
    mA, nA = size(A)
    nB = size(B, 1)
    perm = invperm(B.perm)
    nzval = Vector{promote_type(Tv, Tb)}(mA*nA*nB)
    rowval = Vector{Int}(mA*nA*nB)
    colptr = collect(1:mA:nA*nB*mA+1)
    z = 1
    @inbounds for j = 1:nA
        @inbounds for j2 = 1:nB
            p2 = perm[j2]
            val2 = B.vals[p2]
            ir = p2
            @inbounds @simd for i = 1:mA
                nzval[z] = A[i, j]*val2  # merge
                rowval[z] = ir
                z += 1
                ir += nB
            end
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end

function kron(A::PermMatrix{Ta}, B::StridedMatrix{Tb}) where {Tb, Ta}
    mB, nB = size(B)
    nA = size(A, 1)
    perm = invperm(A.perm)
    nzval = Vector{promote_type(Ta, Tb)}(mB*nA*nB)
    rowval = Vector{Int}(mB*nA*nB)
    colptr = collect(1:mB:nA*nB*mB+1)
    z = 1
    @inbounds for j = 1:nA
        colbase = (j-1)*nB
        p1 = perm[j]
        val2 = A.vals[p1]
        ir = (p1-1)*mB
        @inbounds for j2 = 1:nB
            @inbounds @simd for i2 = 1:mB
                nzval[z] = B[i2, j2]*val2  # merge
                rowval[z] = ir+i2
                z += 1
            end
        end
    end
    SparseMatrixCSC(nA*mB, nA*nB, colptr, rowval, nzval)
end

function kron(A::PermMatrix, B::PermMatrix) 
    nA = size(A, 1)
    nB = size(B, 1)
    vals = kron(A.vals, B.vals)
    perm = Vector{Int}(nB*nA)
    @inbounds for i = 1:nA
        start = (i-1)*nB
        permAi = (A.perm[i]-1)*nB
        @inbounds @simd for j = 1:nB
            perm[start+j] = permAi +B.perm[j]
        end
    end
    PermMatrix(perm, vals)
end

kron(A::PermMatrix, B::Diagonal) = kron(A, PermMatrix(B))
kron(A::Diagonal, B::PermMatrix) = kron(PermMatrix(A), B)

function kron(A::PermMatrix{Ta}, B::SparseMatrixCSC{Tb}) where {Ta, Tb}
    nA = size(A, 1)
    mB, nB = size(B)
    nV = nnz(B)
    perm = invperm(A.perm)
    nzval = Vector{promote_type(Ta, Tb)}(nA*nV)
    rowval = Vector{Int}(nA*nV)
    colptr = Vector{Int}(nA*nB+1)
    colptr[1] = 1
    @inbounds @simd for i in 1:nA
        start_row = (i-1)*nV
        start_ri = (perm[i]-1)*mB
        v0 = A.vals[perm[i]]
        @inbounds @simd for j = 1:nV
            nzval[start_row+j] = B.nzval[j]*v0
            rowval[start_row+j] = B.rowval[j] + start_ri
        end
        start_col = (i-1)*nB+1
        start_ci = (i-1)*nV
        @inbounds @simd for j = 1:nB
            colptr[start_col+j] = B.colptr[j+1] + start_ci
        end
    end
    SparseMatrixCSC(mB*nA, nB*nA, colptr, rowval, nzval)
end

function kron(A::SparseMatrixCSC{T}, B::PermMatrix{Tb}) where {T, Tb}
    nB = size(B, 1)
    mA, nA = size(A)
    nV = nnz(A)
    perm = invperm(B.perm)
    rowval = Vector{Int}(nB*nV)
    colptr = Vector{Int}(nA*nB+1)
    nzval = Vector{promote_type(T, Tb)}(nB*nV)
    z=1
    colptr[z] = 1
    @inbounds for i in 1:nA
        rstart = A.colptr[i]
        rend = A.colptr[i+1]-1
        @inbounds for k in 1:nB
            irow = perm[k]
            bval = B.vals[irow]
            irow_nB = irow - nB
            @inbounds @simd for r in rstart:rend
                rowval[z] = A.rowval[r]*nB+irow_nB
                nzval[z] = A.nzval[r]*bval
                z+=1
            end
            colptr[(i-1)*nB+k+1] = z
        end
    end
    SparseMatrixCSC(mA*nB, nA*nB, colptr, rowval, nzval)
end
