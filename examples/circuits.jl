using Yao.EasyBuild, YaoPlots, Yao

lighttheme!()
YaoPlots.CircuitStyles.gate_bgcolor[] = "white"  # default is transparent
# qft circuit
vizcircuit(qft_circuit(5); filename=joinpath(@__DIR__, "qft.png"))

# labeled and time evolution
vizcircuit(chain(control(5, 3, (2,4)=>matblock(rand_unitary(4); tag="label")),
    put(5, (2,4)=>matblock(rand_unitary(4); tag="labellabel")), time_evolve(+(put(5, 2=>X), kron(5, 2=>Z, 3=>Y)), 0.2)), filename=joinpath(@__DIR__, "labelled.png"))

# variational circuit
vizcircuit(variational_circuit(5), filename=joinpath(@__DIR__, "variational.png"))
# vizcircuit(variational_circuit(5; mode=:Merged))

# general U4 gate
vizcircuit(general_U4(), filename=joinpath(@__DIR__, "u4.png"))

# quantum supremacy circuit
vizcircuit(rand_supremacy2d(2, 2, 8), filename=joinpath(@__DIR__, "supremacy2d.png"))

# google 52 qubit
vizcircuit(rand_google53(5); filename=joinpath(@__DIR__, "google53.png"))

# control blocks
vizcircuit(chain(control(5, (2,-3), 4=>X), control(5, (-4, -2), 1=>Z)), filename=joinpath(@__DIR__, "controls.png"))

# controlled kron
vizcircuit(control(4, 2, (1, 3)=>kron(X, X)), filename=joinpath(@__DIR__, "cxx.png"))

vizcircuit(control(4, -collect(1:4-1), 4=>-Z), filename=joinpath(@__DIR__, "reflect.png"))

vizcircuit(chain(5, [put(5, 2=>X), Yao.Measure(5; locs=(2,3)), Yao.Measure(5;locs=(2,)), Yao.Measure(5; resetto=bit"00110")]), filename=joinpath(@__DIR__, "measure.png"))

vizcircuit(chain(5, [put(5, 2=>ConstGate.Sdag), put(5, 3=>ConstGate.Tdag),
    put(5, (2,3)=>ConstGate.CNOT), put(5, (1,4)=>ConstGate.CZ), put(5, (1,2,5)=>ConstGate.Toffoli),
    put(5, (2,3)=>ConstGate.SWAP), put(5, (1,)=>ConstGate.P0), put(5, (1,)=>ConstGate.I2),
    put(5, (2,)=>ConstGate.P1), put(5, (1,)=>ConstGate.Pu), put(5, (1,)=>ConstGate.Pd),
    put(5, (2,)=>ConstGate.T),
    put(5, (2,)=>phase(0.4π)),
    put(5, (2,)=>shift(0.4π)),
    ]), filename=joinpath(@__DIR__, "constgates.png"))

vizcircuit(chain(5, [put(5, (2,3)=>matblock(Matrix(SWAP), tag="SWAP")'), put(5, 2=>matblock(mat(I2), tag="id")), put(5, 2=>addlabel(X, "Xr")), control(5, (5,3), (2,4,1)=>put(3, (1,3)=>addlabel(SWAP, "SWAP")))]), filename=joinpath(@__DIR__, "multiqubit.png"))

YaoPlots.darktheme!()
YaoPlots.CircuitStyles.gate_bgcolor[] = "transparent"  # default is transparent
# qft circuit
vizcircuit(qft_circuit(5), filename=joinpath(@__DIR__, "qft-white.png"))

