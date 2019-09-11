using YaoBase, SparseArrays, BitBasis, YaoArrayRegister, SymEngine
export @ket_str, @bra_str

YaoArrayRegister._warn_type(raw::AbstractArray{Basic}) = nothing

const SymReg{B, MT} = ArrayReg{B, Basic, MT}
const AdjointSymReg{B, MT} = AdjointArrayReg{B, Basic, MT}

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

function ket_m(s)
    v, N = parse_str(s)
    st = spzeros(Basic, 1 << N, 1)
    st[v+1] = 1
    return ArrayReg{1}(st)
end

function bra_m(s)
    adjoint(ket_m(s))
end

macro ket_str(s)
    ket_m(s)
end

macro bra_str(s)
    bra_m(s)
end

function SymEngine.expand(x::SymReg{B}) where B
    ArrayReg{B}(expand.(x.state))
end

function Base.show(io::IO, r::SymReg{1})
    rows = rowvals(r.state)
    nnz = nonzeros(r.state)
    if size(r.state, 2) == 1 # all actived
        for i in nzrange(r.state, 1)
            k = rows[i]
            v = nnz[i]
            if isone(v)
                print(io, "|", string(k-1, base=2, pad=nactive(r)), "⟩")
            else
                print(io, v, "|", string(k-1, base=2, pad=nactive(r)), "⟩")
            end

            if i != last(nzrange(r.state, 1))
                print(io, " + ")
            end
        end
    end
end

function Base.show(io::IO, r::AdjointSymReg{1})
    rows = rowvals(parent(state(r)))
    nnz = nonzeros(parent(state(r)))
    nzr = nzrange(parent(state(r)), 1)
    if size(parent(state(r)), 2) == 1 # all actived
        for i in nzr
            k = rows[i]
            v = adjoint(nnz[i])
            if isone(v)
                print(io, "⟨", string(k-1, base=2, pad=nactive(r)), "|")
            else
                print(io, v, "⟨", string(k-1, base=2, pad=nactive(r)), "|")
            end

            if i != last(nzr)
                print(io, " + ")
            end
        end
    end
end
