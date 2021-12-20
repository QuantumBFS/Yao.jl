using TupleTools

NotImplementedError(name::Symbol) = NotImplementedError(name, ())

function Base.show(io::IO, e::NotImplementedError)
    str = join(map(typeof, e.args), ", ::")
    str = "::" * str
    print(
        io,
        "NotImplementedError: $(e.name) is not implemented for (",
        str,
        "), ",
        "please implement this method for your custom type",
    )
end

function Base.show(io::IO, e::NotImplementedError{Tuple{}})
    print(io, "$(e.name) is not implemented.")
end

function Base.show(io::IO, e::LocationConflictError)
    print(io, "LocationConflictError: ", e.msg)
    # print(io, "locations of $(e.blk1) and $(e.blk2) is conflict.")
end

function show(io::IO, e::QubitMismatchError)
    print(io, e.msg)
end


export islocs_inbounds, islocs_conflict

_sort(x::Vector; by = identity) = sort(x, by = by)
_sort(x::Tuple; by = identity) = TupleTools.sort(x, by = by)

# NOTE: this method assumes its input is not empty, it gets rid of errors
nonempty_minimum(x::UnitRange) = x.start
nonempty_minimum(x::Integer) = x
nonempty_maximum(x::UnitRange) = x.stop
nonempty_maximum(x::Integer) = x

const AddressVector{T} = Vector{T} where {T<:Union{Integer,UnitRange}}
const AddressNTuple{N,T} = NTuple{N,T} where {T<:Union{Integer,UnitRange}}
const AddressList{T} = Union{AddressVector{T},AddressNTuple{N,T} where N}

"""
    islocs_inbounds(n, locs) -> Bool

Check if the input locations are inside given bounds `n`.
"""
function islocs_inbounds(n::Int, locs::AddressList)
    length(locs) == 0 && return true
    locs = _sort(locs, by = x -> nonempty_minimum(x))
    (minimum(first(locs)) > 0 && maximum(last(locs)) <= n) || return false
    return true
end

"""
    islocs_conflict(locs) -> Bool

Check if the input locations has conflicts.
"""
function islocs_conflict(locs::AddressList)
    locs = _sort(locs)
    for i = 1:length(locs)-1
        nonempty_minimum(locs[i+1]) > nonempty_maximum(locs[i]) || return true
    end
    return false
end

function process_msgs(msgs...; default = "")
    msg = isempty(msgs) ? default : msgs[1]
    if isa(msg, AbstractString)
        msg = msg # pass-through
    elseif !isempty(msgs) && (isa(msg, Expr) || isa(msg, Symbol))
        # message is an expression needing evaluating
        msg = :(Main.Base.string($(esc(msg))))
    elseif isdefined(Main, :Base) &&
           isdefined(Main.Base, :string) &&
           applicable(Main.Base.string, msg)
        msg = Main.Base.string(msg)
    else
        # string() might not be defined during bootstrap
        msg = :(Main.Base.string($(Expr(:quote, msg))))
    end
    return msg
end


# NOTE: we may use @assert in the future
#       these macro will help us keep original APIs
export @assert_locs_safe, @assert_locs_inbounds

"""
    @assert_locs_inbounds <number of total qubits> <locations list> [<msg>]

Assert if all the locations are inbounds.
"""
macro assert_locs_inbounds(n, locs, msgs...)
    msg = process_msgs(msgs...; default = "locations is out of bounds!")

    return quote
        islocs_inbounds($(esc(n)), $(esc(locs))) || error($msg)
        nothing
    end
end

"""
    @assert_locs_safe <number of total qubits> <locations list> [<msg>]

Assert if all the locations are:
    - inbounds.
    - do not have any conflict.
"""
macro assert_locs_safe(n, locs, msgs...)
    msg = process_msgs(msgs...; default = "locations conflict.")
    return quote
        @assert_locs_inbounds $(esc(n)) $(esc(locs))
        islocs_conflict($(esc(locs))) && throw(LocationConflictError($msg))
        nothing
    end
end
