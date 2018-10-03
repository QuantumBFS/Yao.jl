using Base: depwarn
export blocks

function blocks(blk::AbstractBlock)
    depwarn("`blocks` will be renamed to `subblocks` to avoid confusion.")
    subblocks(blk)
end
