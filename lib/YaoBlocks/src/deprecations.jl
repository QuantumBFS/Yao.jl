# deprecations
@deprecate iparameters(args...) getiparams(args...)
@deprecate setiparameters!(args...) setiparams!(args...)
@deprecate niparameters(args...) niparams(args...)
@deprecate parameter_type(args...) parameters_eltype(args...)
@deprecate PreserveStyle(args...) PropertyTrait(args...)
@deprecate Sum(args...) Add(args...)
@deprecate mathgate(f; nbits) mathgate(nbits, f)
@deprecate Concentrator Subroutine
@deprecate concentrate subroutine

@deprecate UnitaryChannel(args...) MixedUnitaryChannel(args...)
@deprecate pauli_error_channel(; px::Real, py::Real=px, pz::Real=px) UnitaryChannel(PauliError(px, py, pz))
@deprecate bit_flip_channel(p::Real) UnitaryChannel(BitFlipError(p))
@deprecate phase_flip_channel(p::Real) UnitaryChannel(PhaseFlipError(p))
@deprecate single_qubit_depolarizing_channel(p::Real) UnitaryChannel(DepolarizingError(p))
@deprecate unitary_channel mixed_unitary_channel
@deprecate reset_error(; p0::Real, p1::Real) KrausChannel(ResetError(p0, p1))