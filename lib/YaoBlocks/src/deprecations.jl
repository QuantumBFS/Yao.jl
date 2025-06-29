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
@deprecate unitary_channel MixedUnitaryChannel
@deprecate reset_error_channel(; p0::Real, p1::Real) KrausChannel(ResetError(p0, p1))
@deprecate pauli_error_channel(; px::Real, py::Real=px, pz::Real=px) MixedUnitaryChannel(PauliError(px, py, pz))
@deprecate single_qubit_depolarizing_channel(p::Real) quantum_channel(DepolarizingError(1, p))
@deprecate phase_flip_channel(p::Real) quantum_channel(PhaseFlipError(p))
@deprecate bit_flip_channel(p::Real) quantum_channel(BitFlipError(p))
@deprecate mixed_unitary_channel(operators, probs::AbstractVector) MixedUnitaryChannel(operators, probs)
@deprecate depolarizing_channel(n::Int; p::Real) DepolarizingChannel(n, p)
@deprecate kraus_channel(operators) KrausChannel(operators)

@deprecate two_qubit_depolarizing_channel(p::Real) MixedUnitaryChannel(
        [kron(I2, I2), kron(I2, X), kron(I2, Y), kron(I2, Z),
         kron(X, I2), kron(X, X), kron(X, Y), kron(X, Z),
         kron(Y, I2), kron(Y, X), kron(Y, Y), kron(Y, Z),
         kron(Z, I2), kron(Z, X), kron(Z, Y), kron(Z, Z),
        ],
        [1-15p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
         p/16, p/16, p/16, p/16,
        ],
    )
