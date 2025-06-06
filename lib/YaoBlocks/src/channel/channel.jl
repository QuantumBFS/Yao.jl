export AbstractErrorType, BitFlipError, PhaseFlipError, DepolarizingError, PauliError, ResetError,
    KrausChannel, MixedUnitaryChannel, kraus_channel, mixed_unitary_channel,
    depolarizing_channel,
    two_qubit_depolarizing_channel,
    SuperOp

include("superop.jl")
include("kraus.jl")
include("unitary_channel.jl")
include("errortypes.jl")
include("error_channel.jl")
