# Base.zero(pm::PermMatrix) = PermMatrix(pm.perm, zero(pm.vals))

# TODO
# to make a mat block differentiable
#YaoBlocks.niparams(x::GeneralMatrixBlock{N,N,D}) where {N,D} = D ^ {2N}
#YaoBlocks.getiparams(x::GeneralMatrixBlock) where N = (vec(x.mat)...,)

# to make a scale block differentiable
#YaoBlocks.niparams(x::Scale{<:Number}) = 1
#YaoBlocks.getiparams(x::Scale{<:Number}) = factor(x)
