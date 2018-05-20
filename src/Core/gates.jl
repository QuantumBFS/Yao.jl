include("basis.jl")
include("permmul.jl")

function xgate(bits::Ints, basis::Vector{DInt})
    norder = flip(basis, bits)
    PermuteMultiply(norder+1, ones(length(basis)))
end

function ygate(bits::Ints, basis::Vector{DInt})
    norder = flip(basis, bits)
    #vals = [-im*(-1)^reduce(+,takebit(b, bits)) for b in basis]
    #vals = mapreduce(bit->map(x->x==0?-im:im, takebit(basis, bit)), .*, bits)
    vals = mapreduce(bit->im.*(2.*takebit(basis, bit).-1), .*, bits)
    PermuteMultiply(norder+1, vals)
end

function zgate(bits::Ints, basis::Vector{DInt})
    #vals = [(-1)^reduce(+,takebit(b, bits)) for b in basis]
    vals = mapreduce(bit->1.-2.*takebit(basis, bit), .*, bits)
    PermuteMultiply(basis+1, vals)
end

# arbitrary off-diagonal single qubit gate
function ndgate(bits::Ints, basis::Vector{DInt}, phi::Float64)
    norder = flip(basis, bits)
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis, bit).-1)), .*, bits)
    PermuteMultiply(norder+1, vals)
end

# arbitrary diagonal single qubit gate
function dgate(bits::Ints, basis::Vector{DInt}, phi::Float64)
    vals = mapreduce(bit->exp.(im*phi*(2.*takebit(basis, bit).-1)), .*, bits)
    PermuteMultiply(basis+1, vals) # or Diagonal(vals) ?
end

#TODO
# arbituary dense single qubit gate: SparseMatrixCSC
