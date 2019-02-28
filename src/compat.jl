using TupleTools

diff(v::AbstractVector) = Base.diff(v)

@static if isdefined(TupleTools, :diff)
    diff(v::Tuple) = TupleTools.diff(v)
else
    diff(v::Tuple{}) = () # similar to diff([])
    diff(v::Tuple{Any}) = ()
    diff(v::Tuple) = (v[2]-v[1], diff(Base.tail(v))...)
end
