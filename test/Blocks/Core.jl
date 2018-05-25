using Compat.Test
using QuCircuit

@test dispatch!(+, X()) == X()
