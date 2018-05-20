# literals

export @bit_str, asindex

struct QuBitStr
    val::UInt
    len::Int
end

import Base: length
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

# Integer Logrithm of 2
# Ref: https://stackoverflow.com/questions/21442088
export log2i

function bit_length(x)
    local n = 0
    while x!=0
        n += 1
        x >>= 1
    end
    return n
end

"""
    log2i(x)

logrithm for integer pow of 2
"""
function log2i(x::T)::T where T
    local n::T = 0
    while x&0x1!=1
        n += 1
        x >>= 1
    end
    return n
end

export batch_normalize!

"""
    batch_normalize!(matrix)

normalize a batch of vector.
"""
function batch_normalize!(s::AbstractMatrix)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i))
    end
    s
end

"""
    batch_normalize

normalize a batch of vector.
"""
function batch_normalize(s::AbstractMatrix)
    ts = copy(s)
    batch_normalize!(ts)
end

kronprod(itr) = reduce(kron, speye(1), itr)

############
# Constants
############

# NOTE: we define some type related constants here to avoid multiple allocation

import Compat

for (NAME, MAT) in [
    ("P0", [1 0;0 0]),
    ("P1", [0 0;0 1]),
    ("PAULI_X", [0 1;1 0]),
    ("PAULI_Y", [0 -im; im 0]),
    ("PAULI_Z", [1 0;0 -1]),
    ("HADMARD", (elem = 1 / sqrt(2); [elem elem; elem -elem]))
]

    DENSE_NAME = Symbol(join(["CONST", NAME], "_"))
    SPARSE_NAME = Symbol(join(["CONST", "SPARSE", NAME], "_"))

    for (TYPE_NAME, DTYPE) in [
        ("ComplexF16", Compat.ComplexF16),
        ("ComplexF32", Compat.ComplexF32),
        ("ComplexF64", Compat.ComplexF64),
    ]

        DENSE_CONST = Symbol(join([DENSE_NAME, TYPE_NAME], "_"))
        SPARSE_CONST = Symbol(join([SPARSE_NAME, TYPE_NAME], "_"))

        @eval begin
            const $(DENSE_CONST) = Array{$DTYPE, 2}($MAT)
            const $(SPARSE_CONST) = sparse(Array{$DTYPE, 2}($MAT))

            $(DENSE_NAME)(::Type{$DTYPE}) = $(DENSE_CONST)
            $(SPARSE_NAME)(::Type{$DTYPE}) = $(SPARSE_CONST)
        end
    end

    @eval begin
        #default type
        $(DENSE_NAME)() = $(DENSE_NAME)(Compat.ComplexF64)
        $(SPARSE_NAME)() = $(SPARSE_NAME)(Compat.ComplexF64)

        # fallback methods for other types
        $(DENSE_NAME)(::Type{T}) where T = Array{T, 2}(MAT)
        $(SPARSE_NAME)(::Type{T}) where T = sparse($(DENSE_NAME)(T))
    end

end

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

@generated function rolldims!(::Type{Val{K}}, ::Type{Val{N}}, ::Type{Val{B}}, st::AbstractMatrix) where {K, N, B}
    ex = :(rolldims2!(Val{$N}, Val{$B}, st))
    for i = 2:K
        ex = :(rolldims2!(Val{$N}, Val{$B}, st); $ex)
    end
    ex
end
