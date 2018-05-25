function repeat2(a::AbstractVector, m::Integer)
    o = length(a)
    b = similar(a, o*m)
    for i=1:m
        c = (i-1)*o+1
        @inbounds @simd for j = 1:o
            b[c + j - 1] = a[j]
        end
    end
    return b
end
