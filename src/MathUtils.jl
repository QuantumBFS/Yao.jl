export @bit_str, asindex

struct QuBitStr
    val::UInt
    len::Int
end

import Base: length

# use system interface
asindex(bits::QuBitStr) = bits.val + 1
length(bits::QuBitStr) = bits.len

macro bit_str(str)
    @assert length(str) < 64 "we do not support large integer at the moment"
    val = unsigned(0)
    for (k, each) in enumerate(reverse(str))
        if each == '1'
            val += 1 << (k - 1)
        end
    end
    QuBitStr(val, length(str))
end

import Base: show

function show(io::IO, bitstr::QuBitStr)
    print(io, "QuBitStr(", bitstr.val, ", ", bitstr.len, ")")
end

export batch_normalize!, batch_normalize

"""
    batch_normalize!(matrix)

normalize a batch of vector.
"""
function batch_normalize!(s::AbstractMatrix, p::Real=2)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i), p)
    end
    s
end

"""
    batch_normalize

normalize a batch of vector.
"""
function batch_normalize(s::AbstractMatrix, p::Real=2)
    ts = copy(s)
    batch_normalize!(ts, p)
end

export kronprod

"""
    kronprod(itr)

kronecker product all operators in the iterator.
"""
kronprod(itr) = reduce(kron, speye(1), itr)

# N: number of qubits
# st: state vector with batch
function rolldims2!(::Type{Val{N}}, ::Type{Val{B}}, st::AbstractMatrix) where {N, B}
    n = 1 << N
    halfn = 1 << (N - 1)
    temp = st[2:2:n, :]
    st[1:halfn, :] = st[1:2:n, :]
    st[halfn+1:end, :] = temp
    st
end

function rolldims2!(::Type{Val{N}}, ::Type{Val{1}}, st::AbstractVector) where {N}
    n = 1 << N
    halfn = 1 << (N - 1)
    temp = st[2:2:n]
    st[1:halfn] = st[1:2:n]
    st[halfn+1:end] = temp
    st
end

@generated function rolldims!(::Type{Val{K}}, ::Type{Val{N}}, ::Type{Val{B}}, st::AbstractVecOrMat) where {K, N, B}
    ex = :(rolldims2!(Val{$N}, Val{$B}, st))
    for i = 2:K
        ex = :(rolldims2!(Val{$N}, Val{$B}, st); $ex)
    end
    ex
end

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

import Base: randn, invperm
randn(T::Type{Complex{F}}, n::Int...) where F = randn(F, n...) + im*randn(F, n...)

function invperm(order)
    v = similar(order)
    @inbounds @simd for i=1:length(order)
        v[order[i]] = i
    end
    v
end
