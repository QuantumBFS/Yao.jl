export UnitaryChannel, unitary_channel,
    phase_flip_channel,
    bit_flip_channel,
    depolarizing_channel,
    single_qubit_depolarizing_channel,
    two_qubit_depolarizing_channel,
    pauli_error_channel

include("kraus.jl")
include("unitary_channel.jl")
include("error_channel.jl")
