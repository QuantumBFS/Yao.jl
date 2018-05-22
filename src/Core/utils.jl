function subtypetree(t, level=1, indent=4)
    level == 1 && println(t)
    for s in subtypes(t)
        println(join(fill(" ", level * indent)) * string(s))
        subtypetree(s, level+1, indent)
    end
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

import Base: randn
randn(T::Type{Complex{F}}, n::Int...) where F = randn(F, n...) + im*randn(F, n...)

function invperm(order)
    v = similar(order)
    @inbounds @simd for i=1:length(order)
        v[order[i]] = i
    end
    v
end

allclose(x, y, tol::Real=1e-8) = all(isapprox.(x,y, atol=tol))
