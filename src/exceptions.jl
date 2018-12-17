export NotImplementedError

struct NotImplementedError{ArgsT} <: Exception
    name::Symbol
    args::ArgsT
end

NotImplementedError(name::Symbol) = NotImplementedError(name, ())

function Base.show(io::IO, e::NotImplementedError{<:Tuple})
    str = join(map(typeof, e.args), ", ::")
    str = "::" * str
    print(io, "$(e.name) is not implemented for (", str, "),
        please implement this method for your custom type")
end

function Base.show(io::IO, e::NotImplementedError{Tuple{}})
    print(io, "$(e.name) is not implemented.")
end

struct AddressConflictError{T1, T2} <: Exception
    blk1::T1
    blk2::T2
end

function Base.show(io::IO, e::AddressConflictError)
    print(io, "address of $(e.blk1) and $(e.blk2) is conflict.")
end
