using YaoBase, SparseArrays, BitBasis, YaoArrayRegister
export @ket_str, @bra_str

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

function ket_m end

function bra_m(s)
    adjoint(ket_m(s))
end

"""
    @ket_str

Create a ket register. See also [`@bra_str`](@ref).

# Example

a symbolic quantum state can be created simply by

```jldoctest
julia> ket"110" + 2ket"111"
|110⟩ + 2|111⟩
```

qubits can be partially actived by [`focus!`](@ref)

```jldoctest
```

"""
macro ket_str(s)
    ket_m(s)
end

macro bra_str(s)
    bra_m(s)
end

function print_braket(f, io::IO, r)
    print(io, "|")
    f()
    print(io, "⟩")
end

function print_braket(f, io::IO, r::AdjointArrayReg)
    print(io, "⟨")
    f()
    print(io, "|")
end

function print_basis(io, active::Int, remain::Int, r)
    print_braket(io, r) do
        printstyled(io, string(remain, base=2, pad=nremain(r)), color=:light_black)
        print(io, string(active, base=2, pad=nactive(r)))
    end
end

function print_sym_state(io::IO, r::ArrayReg{1})
    st = state(r)
    m, n = size(st)
    isfirst_nonzero = true
    amp = st[1, 1]
    if !iszero(amp)
        isone(amp) || print(io, amp)
        print_basis(io, 0, 0, r)
        isfirst_nonzero = false
    end

    for j in 1:n, i in 1:m
        i ==1 && j == 1 && continue
        amp = st[i, j]
        if iszero(amp)
            continue
        end

        isfirst_nonzero || print(io, " + ")
        isone(amp) || print(io, st[i, j])
        print_basis(io, i-1, j-1, r)
        isfirst_nonzero = false
    end
end

function print_sym_state(io::IO, r::AdjointArrayReg{1})
    st = state(r)
    m, n = size(st)
    isfirst_nonzero = true
    amp = st[1, 1]
    if !iszero(amp)
        isone(amp) || print(io, amp)
        print_basis(io, 0, 0, r)
        isfirst_nonzero = false
    end

    for j in 1:n, i in 1:m
        i ==1 && j == 1 && continue
        amp = st[i, j]
        if iszero(amp)
            continue
        end

        isfirst_nonzero || print(io, " + ")
        isone(amp) || print(io, st[i, j])
        print_basis(io, j-1, i-1, r)
        isfirst_nonzero = false
    end
end

# TODO: need a more extensible implementation
# Base.:(*)(x::SymReg{B, MT}, y::SymReg{B, MT}) where {B, MT} = SymReg{B, MT}(kron(state(x), state(y)))
# Base.:(^)(x::SymReg{B, MT}, n::Int) where {B, MT} = SymReg{B, MT}(kron(state(x) for _ in 1:n))

# Base.:(*)(x::AdjointSymReg{B, MT}, y::AdjointSymReg{B, MT}) where {B, MT} = adjoint(parent(x) * parent(y))
# Base.:(^)(x::AdjointSymReg{B, MT}, n::Int) where {B, MT} = adjoint(parent(x)^n)
