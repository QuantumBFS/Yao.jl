export AddressConflictError, QubitMismatchError

import Base: show

"""
    AddressConflictError <: Exception

Address conflict error in Block Construction.
"""
struct AddressConflictError <: Exception
    msg::String
end

function show(io::IO, e::AddressConflictError)
    print(io, e.msg)
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
