using TupleTools

diff(v::AbstractVector) = Base.diff(v)
diff(v::Tuple) = TupleTools.diff(v)
