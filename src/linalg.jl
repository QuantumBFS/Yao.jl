################# Scale #################
Base.:*(x::Number, blk::MatrixBlock) = Scale(blk, x)
Base.:*(blk::MatrixBlock, x::Number) = Scale(blk, x)
Base.:*(g1::Scale, g2::MatrixBlock) = Scale(parent(g1)*g2, factor(g1))
Base.:*(g2::MatrixBlock, g1::Scale) = Scale(g2*parent(g1), factor(g1))
Base.:*(x::Number, blk::Scale) = Scale(blk, x)
Base.:*(blk::Scale, x::Number) = Scale(blk, x)
Base.:*(g1::Scale, g2::Scale) = Scale(parent(g1)*parent(g2), factor(g1)*factor(g2))

Base.:*(g1::StaticScale, g2::MatrixBlock) = StaticScale(parent(g1)*g2, factor(g1))
Base.:*(g2::MatrixBlock, g1::StaticScale) = StaticScale(g2*parent(g1), factor(g1))
Base.:*(x::Number, blk::StaticScale) = StaticScale(blk, x)
Base.:*(blk::StaticScale, x::Number) = StaticScale(blk, x)
Base.:*(g1::StaticScale, g2::StaticScale) = StaticScale(parent(g1)*parent(g2), factor(g1)*factor(g2))

Base.:-(blk::AbstractScale) = chfactor(blk, -factor(blk))
Base.:-(blk::MatrixBlock) = -1*blk
Base.:-(blk::Neg) = blk.block

Base.:+(a::MatrixBlock{N}, b::MatrixBlock{N}) where N = AddBlock(a, b)
Base.:+(a::AddBlock{N, T1}, b::MatrixBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a.blocks...; b])
Base.:+(a::MatrixBlock{N, T1}, b::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a; b.blocks...])
Base.:+(a::AddBlock{N, T1}, b::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a.blocks...; b.blocks...])

# the following lines will expand expressions, which may raise exploding number of terms
#Base.:*(x::AddBlock{N, T1}, y::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([b*c for b in subblocks(x), c in subblocks(y)] |> vec)
#Base.:*(a::AddBlock{N, T}, x::T2) where {N, T, T2<:Number} = AddBlock{N, promote_type(T, T2)}([b*x for b in subblocks(a)])
#Base.:*(x::T2, a::AddBlock{N, T}) where {N, T, T2<:Number} = AddBlock{N, promote_type(T, T2)}([x*b for b in subblocks(a)])
#Base.:*(y::AddBlock{N, T}, x::MatrixBlock{N, T2}) where {N, T, T2} = AddBlock{N, promote_type(T, T2)}([b*x for b in subblocks(y)])
#Base.:*(x::MatrixBlock{N, T2}, y::AddBlock{N, T}) where {N, T, T2} = AddBlock{N, promote_type(T, T2)}([x*b for b in subblocks(y)])

Base.:*(x::MatrixBlock{N}, y::MatrixBlock{N}) where N = ChainBlock(y, x)
Base.:*(x::ChainBlock{N, T1}, y::MatrixBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y; x...])
Base.:*(x::MatrixBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x])
Base.:*(x::ChainBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x...])

# fix scale chain ambiguous
Base.:*(g1::Scale, g2::ChainBlock) = Scale(parent(g1)*g2, factor(g1))
Base.:*(g2::ChainBlock, g1::Scale) = Scale(g2*parent(g1), factor(g1))

# fix add chain ambiguous
Base.:*(x::ChainBlock{N, T1}, y::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([x*b for b in subblocks(y)])
Base.:*(x::AddBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([b*y for b in subblocks(x)])

Base.:^(blk::MatrixBlock, n::Int) = ChainBlock(fill(blk, n))
