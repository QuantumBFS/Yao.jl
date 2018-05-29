struct RangedBlock{BT, RT}
    block::BT
    range::RT
end

function show(io::IO, x::RangedBlock{BT, Int}) where BT
    print(io, x.block, " at line ", x.range)
end

function show(io::IO, x::RangedBlock)
    print(io, x.block, " in line range ", x.range)
end
