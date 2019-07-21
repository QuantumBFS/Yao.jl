export Const

"""
    Const

Contains common constant definitions.
"""
module Const

using LuxurySparse, LinearAlgebra, SparseArrays
using YaoBase.ASTTools

"""
    @def name = value

Define a constant and export it.
"""
macro def(ex)
    list = @capture($name = $m)(ex)
    quote
        export $(esc(list[:name]))
        Core.@__doc__ const $(esc(list[:name])) = $(list[:m])
    end
end

@def P0 = ComplexF64[1 0;0 0];
@def P1 = ComplexF64[0 0;0 1];
@def X  = PermMatrix([2,1], ComplexF64[1+0im, 1]);
@def Y  = PermMatrix([2,1], ComplexF64[-im, im]);
@def Z  = Diagonal(ComplexF64[1+0im, -1]);
@def S  = Diagonal(ComplexF64[1, im]);
@def Sdag = Diagonal(ComplexF64[1, -im]);
@def T = Diagonal(ComplexF64[1, exp(π*im/4)]);
@def Tdag = Diagonal(ComplexF64[1, exp(-π*im/4)]);
@def I2 = IMatrix{2, ComplexF64}();
@def H = (elem = 1 / sqrt(2); ComplexF64[elem elem; elem -elem])
@def CNOT = PermMatrix([1, 4, 3, 2], ones(ComplexF64, 4));
@def CZ = Diagonal([1.0+0im, 1, 1, -1]);
@def SWAP = PermMatrix([1, 3, 2, 4], ones(ComplexF64, 4));
@def Toffoli = PermMatrix([1, 2, 3, 8, 5, 6, 7, 4], ones(ComplexF64, 8));
@def Pu = sparse([1], [2], ComplexF64[1+0im], 2, 2);
@def Pd = sparse([2], [1], ComplexF64[1+0im], 2, 2);

end
