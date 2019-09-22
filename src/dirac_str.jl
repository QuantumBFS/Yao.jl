using BitBasis: readbit

export @bra_str, @ket_str
abstract type DiracStr{N} <: AbstractVector{Bool} end

# array interface
Base.length(::DiracStr{N}) where N = N
Base.getindex(x::DiracStr, k::Int) = k == x.data + 1 ? 1 : 0
Base.size(x::DiracStr{N}) where N = (1 << N, )

isleaf(::Type{<:DiracStr}) = true
isleaf(::DiracStr) = true
bit_length(::DiracStr{N}) where N = N

struct KetStr{N} <: DiracStr{N}
    data::Int
end

struct BraStr{N} <: DiracStr{N}
    data::Int
end

function parse_str(s::String)
    v = 0; k = 1
    for each in reverse(filter(x->x!='_', s))
        if each == '1'
            v += 1 << (k - 1)
            k += 1
        elseif each == '0'
            k += 1
        elseif each == '_'
            continue
        else
            error("expect 0 or 1, got $each at $k-th bit")
        end
    end
    return v, k-1
end

function ket_m(s::String)
    v, k = parse_str(s)
    return KetStr{k}(v)
end

function bra_m(s::String)
    v, k = parse_str(s)
    return BraStr{k}(v)
end

macro ket_str(s::String)
    ket_m(s)
end

macro bra_str(s::String)
    bra_m(s)
end

# printings
function Base.show(io::IO, x::KetStr{N}) where N
    print(io, "|", string(x.data, base=2, pad=N), "⟩")
end

function Base.show(io::IO, x::BraStr{N}) where N
    print(io, "⟨", string(x.data, base=2, pad=N), "|")
end

function Base.show(io::IO, x::Dot{<:KetStr, <:BraStr})
    print(io, x.lhs, x.rhs)
end

# operations
Base.:(^)(x::KetStr{K}, n) where n = 
Base.adjoint(x::KetStr{N}) where N = BraStr{N}(x.data)
Base.adjoint(x::BraStr{N}) where N = KetStr{N}(x.data)

Base.:(+)(xs::K...) where {K <: DiracStr} = SymExpr(+, collect(xs))
Base.:(*)(x::Number, y::DiracStr) = Scale(x, y)
Base.:(*)(x::DiracStr, y::Number) = y * x

function Base.:(*)(x::KetStr{N}, y::KetStr{M}) where {N, M}
        
end

function Base.:(*)(x::BraStr{N}, y::KetStr{N}) where N
    x.data == y.data ? 1 : 0
end

Base.:(*)(x::KetStr{N}, y::BraStr{N}) where N = Dot(x, y)

function Base.:(*)(x::BraStr{M}, y::KetStr{N}) where {M, N}
    if M > N
        x.data % (1<<N) == y.data || return 0
        BraStr{M-N}(x.data >> N)
    else
        y.data >> (N-M) == x.data || return 0
        KetStr{N-M}(y.data % (1 << (N-M)))
    end
end

sum_length(a::DiracStr{N}, bits::DiracStr...) where N = N + sum_length(bits...)
sum_length(a::DiracStr{N}) where N = N

for T in [BraStr, KetStr]
    @eval function Base.:(*)(xs::$T...)
        total_length = sum_length(xs...)
        val, len = 0, 0

        for k in length(xs):-1:1
            val += xs[k].data << len
            len += bit_length(xs[k])
        end
        return $T{total_length}(val)
    end
end
