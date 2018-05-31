module Sparse

import ..Const: SYM_LIST, TYPE_LIST
using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays


for (NAME, MAT) in SYM_LIST

    for (TYPE_NAME, TYPE) in (TYPE_LIST)

        CONST_NAME = Symbol(join([NAME, TYPE_NAME]))

        @eval begin
            const $CONST_NAME = sparse(Array{$TYPE, 2}($MAT))
            $NAME(::Type{$TYPE}) = $CONST_NAME
        end

    end

    @eval begin
        $NAME(::Type{T}) where T = sparse(Array{T, 2}($MAT))
        $NAME() = $NAME(ComplexF64)
    end

end

end