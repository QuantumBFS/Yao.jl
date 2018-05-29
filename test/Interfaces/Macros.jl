using QuCircuit

# case 1
@compose 8 1=>X # -> KronBlock
@compose X # -> DynamicSize
@compose 8 QuCircuit.X
@compose QuCircuit.X
