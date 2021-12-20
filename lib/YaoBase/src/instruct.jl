# empty gates
instruct!(
    state::AbstractVecOrMat,
    ::Any,
    locs::Tuple{},
    control_locs::NTuple{N1,Int} = (),
    control_configs::NTuple{N2,Int} = (),
) where {N1,N2} = state
