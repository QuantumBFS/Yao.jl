@deprecate register(raw::AbstractMatrix; B=size(raw,2)) ArrayReg{B}(raw)
@deprecate register(raw::AbstractVector) ArrayReg(raw)
@deprecate register(bits::BitStr, nbatch::Int=1) ArrayReg{nbatch}(bits)
@deprecate register(::Type{T}, bits::BitStr, nbatch::Int) where T ArrayReg{nbatch}(T, bits)

@deprecate tracedist(a, b) trace_distance(a, b)
