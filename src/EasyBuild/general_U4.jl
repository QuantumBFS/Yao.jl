"""
Impliments PRA 69.062321.
"""

export general_U2, general_U4

function general_U2(θ1, θ2, θ3; ϕ=nothing)
    gate = Rz(θ3) * Ry(θ2) * Rz(θ1)
    if ϕ !== nothing
        push!(gate, phase(ϕ))
    end
    return gate
end

"""
    general_U4([params...]) -> AbstractBlock

A general two qubits gate decomposed to (CNOT, Ry, Rz), parameters default to 0.

!!!note

    Although the name is U(4), This is actually a SU(4) gate up to a phase, the phase `det(dispatch!(general_U4(), :random))` is fixed to -1.
"""
general_U4() = general_U4(zeros(15))
function general_U4(params)
    if length(params) != 15
        throw(ArgumentError("The number of parameters must be 15, got $(length(params))"))
    end
    return chain(2, [
        put(2, 1=>general_U2(params[1:3]...)),
        put(2, 2=>general_U2(params[4:6]...)),
        cnot(2, 2, 1),
        put(2, 1=>Rz(params[7])),
        put(2, 2=>Ry(params[8])),
        cnot(2, 1, 2),
        put(2, 2=>Ry(params[9])),
        cnot(2, 2, 1),
        put(2, 1=>general_U2(params[10:12]...)),
        put(2, 2=>general_U2(params[13:15]...))
    ])
end
