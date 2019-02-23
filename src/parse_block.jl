parse_block(n::Int, x::Function) = x(n)

function parse_block(n::Int, x::MatrixBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    return x
end

parse_block(n::Int, x::AbstractBlock) = x
