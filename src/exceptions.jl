export NotImplementedError, AddressConflictError, QubitMismatchError

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

struct AddressConflictError <: Exception
    msg::String
end

function Base.show(io::IO, e::AddressConflictError)
    print(io, "AddressConflictError: ", e.msg)
    # print(io, "address of $(e.blk1) and $(e.blk2) is conflict.")
end

# NOTE: More detailed error msg?
"""
    QubitMismatchError <: Exception

Qubit number mismatch error when applying a Block to a Register or concatenating Blocks.
"""
struct QubitMismatchError <: Exception
    msg::String
end

function show(io::IO, e::QubitMismatchError)
    print(io, e.msg)
end
