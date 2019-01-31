################# Scale #################
*(x::Number, blk::MatrixBlock) = Scale(blk, x)
*(blk::MatrixBlock, x::Number) = Scale(blk, x)
*(g1::Scale, g2::MatrixBlock) = Scale(parent(g1)*g2, factor(g1))
*(g2::MatrixBlock, g1::Scale) = Scale(g2*parent(g1), factor(g1))
*(x::Number, blk::Scale) = Scale(blk, x)
*(blk::Scale, x::Number) = Scale(blk, x)
*(g1::Scale, g2::Scale) = Scale(parent(g1)*parent(g2), factor(g1)*factor(g2))

*(g1::StaticScale, g2::MatrixBlock) = StaticScale(parent(g1)*g2, factor(g1))
*(g2::MatrixBlock, g1::StaticScale) = StaticScale(g2*parent(g1), factor(g1))
*(x::Number, blk::StaticScale) = StaticScale(blk, x)
*(blk::StaticScale, x::Number) = StaticScale(blk, x)
*(g1::StaticScale, g2::StaticScale) = StaticScale(parent(g1)*parent(g2), factor(g1)*factor(g2))

-(blk::AbstractScale) = chfactor(blk, -factor(blk))
-(blk::MatrixBlock) = -1*blk
-(blk::Neg) = blk.block
-(A::MatrixBlock, B::MatrixBlock) = A + (-B)

+(a::MatrixBlock{N}, b::MatrixBlock{N}) where N = AddBlock(a, b)
+(a::AddBlock{N, T1}, b::MatrixBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a.blocks...; b])
+(a::MatrixBlock{N, T1}, b::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a; b.blocks...])
+(a::AddBlock{N, T1}, b::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([a.blocks...; b.blocks...])

# the following lines will expand expressions, which may raise exploding number of terms
#*(x::AddBlock{N, T1}, y::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([b*c for b in subblocks(x), c in subblocks(y)] |> vec)
#*(a::AddBlock{N, T}, x::T2) where {N, T, T2<:Number} = AddBlock{N, promote_type(T, T2)}([b*x for b in subblocks(a)])
#*(x::T2, a::AddBlock{N, T}) where {N, T, T2<:Number} = AddBlock{N, promote_type(T, T2)}([x*b for b in subblocks(a)])
#*(y::AddBlock{N, T}, x::MatrixBlock{N, T2}) where {N, T, T2} = AddBlock{N, promote_type(T, T2)}([b*x for b in subblocks(y)])
#*(x::MatrixBlock{N, T2}, y::AddBlock{N, T}) where {N, T, T2} = AddBlock{N, promote_type(T, T2)}([x*b for b in subblocks(y)])

*(x::MatrixBlock{N}, y::MatrixBlock{N}) where N = ChainBlock(y, x)
*(x::ChainBlock{N, T1}, y::MatrixBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y; x...])
*(x::MatrixBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x])
*(x::ChainBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = ChainBlock{N, promote_type(T1, T2)}([y...; x...])

# fix scale chain ambiguous
*(g1::Scale, g2::ChainBlock) = Scale(parent(g1)*g2, factor(g1))
*(g2::ChainBlock, g1::Scale) = Scale(g2*parent(g1), factor(g1))

# fix add chain ambiguous
*(x::ChainBlock{N, T1}, y::AddBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([x*b for b in subblocks(y)])
*(x::AddBlock{N, T1}, y::ChainBlock{N, T2}) where {N, T1, T2} = AddBlock{N, promote_type(T1, T2)}([b*y for b in subblocks(x)])

Base.:^(blk::MatrixBlock, n::Int) = ChainBlock(fill(blk, n))

/(A::MatrixBlock, x::Number) = (1/x)*A
