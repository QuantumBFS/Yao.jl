export NotImplementedError

struct NotImplementedError <: Exception
    name::Symbol
end

function Base.show(io::IO, e::NotImplementedError)
    print(io, "$(e.name) is not implemented for given input.")
end
