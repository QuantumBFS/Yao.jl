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


export isaddrs_inbounds, isaddrs_conflict, isaddrs_contiguous

_sort(x::Vector; by=identity) = sort(x, by=by)
_sort(x::Tuple; by=identity) = TupleTools.sort(x, by=by)

# NOTE: this method assumes its input is not empty, it gets rid of errors
nonempty_minimum(x::UnitRange) = x.start
nonempty_minimum(x::Integer) = x
nonempty_maximum(x::UnitRange) = x.stop
nonempty_maximum(x::Integer) = x

const AddressVector{T} = Vector{T} where {T <: Union{Integer, UnitRange}}
const AddressNTuple{N, T} = NTuple{N, T} where {T <: Union{Integer, UnitRange}}
const AddressList{T} = Union{AddressVector{T}, AddressNTuple{N, T} where N}

"""
    isaddrs_inbounds(n, addrs) -> Bool

Check if the input address are inside given bounds `n`.
"""
function isaddrs_inbounds(n::Int, addrs::AddressList)
    length(addrs) == 0 && return true
    addrs = _sort(addrs, by=x->nonempty_minimum(x))
    (minimum(first(addrs)) > 0 && maximum(last(addrs)) <= n) || return false
    return true
end

"""
    isaddrs_conflict(addrs) -> Bool

Check if the input address has conflicts.
"""
function isaddrs_conflict(addrs::AddressList)
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nonempty_minimum(nxt) > nonempty_maximum(cur) || return false
    end
    return true
end

"""
    isaddrs_contiguous(n::Int, addrs) -> Bool

Check if the input address is contiguous in ``[1, n]``.
"""
function isaddrs_contiguous(n::Int, addrs::AddressList)
    nonempty_minimum(first(addrs)) == 1 || return false
    for (nxt, cur) in zip(addrs[2:end], addrs[1:end-1])
        nonempty_minimum(nxt) == nonempty_maximum(cur) + 1 || return false
    end
    nonempty_maximum(last(addrs)) == n || return false
    return true
end


function process_msgs(msgs...; default="")
    msg = isempty(msgs) ? default : msgs[1]
    if isa(msg, AbstractString)
        msg = msg # pass-through
    elseif !isempty(msgs) && (isa(msg, Expr) || isa(msg, Symbol))
        # message is an expression needing evaluating
        msg = :(Main.Base.string($(esc(msg))))
    elseif isdefined(Main, :Base) && isdefined(Main.Base, :string) && applicable(Main.Base.string, msg)
        msg = Main.Base.string(msg)
    else
        # string() might not be defined during bootstrap
        msg = :(Main.Base.string($(Expr(:quote,msg))))
    end
    return msg
end


# NOTE: we may use @assert in the future
#       these macro will help us keep original APIs
export @assert_addrs, @assert_addrs_inbounds, @assert_addrs_contiguous

"""
    @assert_addrs_inbounds <number of total qubits> <address list> [<msg>]

Assert if all the address are inbounds.
"""
macro assert_addrs_inbounds(n, addrs, msgs...)
    msg = process_msgs(msgs...; default="address is out of bounds!")

    return quote
        isaddrs_inbounds($(esc(n)), $(esc(addrs))) ? nothing : error($msg)
    end
end

"""
    @assert_addrs <number of total qubits> <address list> [<msg>]

Assert if all the address are:
    - inbounds.
    - do not have any conflict.
"""
macro assert_addrs(n, addrs, msgs...)
    msg = process_msgs(msgs...; default="address conflict.")
    return quote
        @assert_addrs_inbounds $(esc(n)) $(esc(addrs))

        isaddrs_conflict($(esc(addrs))) ? nothing :
            throw(AddressConflictError($msg))
    end
end

"""
    @assert_addrs_contiguous <number of qubits> <address list> [<msg>]

Assert if all the address are:
    - inbounds.
    - do not have any conflict.
    - contiguous on address
"""
macro assert_addrs_contiguous(n, addrs, msgs...)
    msg = process_msgs(msgs...; default="address is not contiguous.")
    quote
        @assert_addrs $(esc(n)) $(esc(addrs))
        isaddrs_contiguous($(esc(n)), $(esc(addrs))) ? nothing :
            error($msg)
    end
end
