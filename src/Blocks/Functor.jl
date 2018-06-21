export Functor

"""
    Functor <: AbstractBlock

function block directly applied on register.
"""
struct Functor{TAG} <: AbstractBlock
    apply
    function Functor{TAG}(apply) where TAG
        !isempty(methods(apply)) || throw(ArgumentError("Input is not callable!"))
        new{TAG}(apply)
    end
end

Functor(apply) = Functor{:Default}(apply)
apply!(reg::AbstractRegister, f::Functor) = f.apply(reg)
