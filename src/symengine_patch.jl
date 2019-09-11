export simplify_expi

SymEngine.free_symbols(syms::Union{Real, Complex}) = Basic[]
SymEngine.free_symbols(syms::AbstractArray{T}) where {T<:Union{Real, Complex}} = Basic[]
SymEngine.free_symbols(syms::AbstractArray{T}) where {T<:Union{Basic, SymEngine.BasicType}} = SymEngine.free_symbols(Matrix(syms))
function rand_assign(syms...)
    fs = union(free_symbols.(syms)...)
    Dict(zip(fs, randn(length(fs))))
end

function _basic_approx(x, y; atol=1e-8)
    diff = x-y
    assign = rand_assign(x, y)
    length(assign) > 0 && (diff = subs.(diff, Ref.((assign...,))...))
    nres = ComplexF64.(diff)
    all(isapprox.(nres, 0; atol=atol))
end

Base.:≈(x::AbstractArray{<:Basic}, y::AbstractArray; atol=1e-8) = _basic_approx(x, y, atol=atol)
Base.:≈(x::AbstractArray, y::AbstractArray{<:Basic}; atol=1e-8) = _basic_approx(x, y, atol=atol)
Base.:≈(x::AbstractArray{<:Basic}, y::AbstractArray{<:Basic}; atol=1e-8) = _basic_approx(x, y, atol=atol)
function Base.Complex{T}(a::Basic) where T
    a = SymEngine.evalf(a)
    T(real(a)) + im*T(imag(a))
end

# simplification rules
function simplify_expi(expr::Basic)
    subs(expr, exp(im*Basic(π)/2)=>Basic(im), exp(im*Basic(π))=>-1, exp(im*Basic(π)*3/2)=>-Basic(im))
end
