using Compat.Test
include("gates.jl")

@testset "gate utils" begin
    @test superkron(4, [PAULI_X, PAULI_Y], [3,2]) == II(2) ⊗ PAULI_X ⊗ PAULI_Y ⊗ II(2)
    @test general_controlled_gates(2, [P1], [2], [PAULI_X], [1]) == CNOT
end

@testset "controlled gates" begin
    @test general_controlled_gates(2, [P1], [2], [PAULI_X], [1]) == CNOT
    @test controlled_U1(3, PAULI_Z, [3], 2) == czgate(3, 3, 2) 
    @test czgate(2, 1, 2) == [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1]
    @test general_controlled_gates(12, [P1], [7], [PAULI_Z], [3]) == czgate(12, 7, 3)
    @test cnotgate(2, 2, 1) == [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
    @test general_controlled_gates(12, [P1], [7], [PAULI_X], [3]) == cnotgate(12, 7, 3)
end

@testset "single gate" begin
    @test zgate(4, [1,2,3]) == superkron(4, [PAULI_Z, PAULI_Z, PAULI_Z], [1,2,3])
end

@testset "basic gate" begin
    # check matrixes
    for (gate, MAT) in [
        (xgate, PAULI_X),
        (ygate, PAULI_Y),
        (zgate, PAULI_Z),
        #(hgate, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        @test full(gate(1, 1)) == MAT
    end
    @test toffoligate(3, 2, 3, 1) == TOFFOLI
end

#=
# psi0
# ['sx', 'sy', 'sz', 'rx(np.pi/6)', 'ry(np.pi/6)', 'rz(np.pi/6)', 'rot(np.pi/6, np.pi/3, np.pi/6)'] apply on 6
# above gates controled by c(4)
# above gates controled by c(2)nc(4)c(5)
psi = loadldm("psi-test.jl")
psi = psi[:, 1:2:end] + im * psi[:, 2:2:end]
psi0 = psi[1,:]
num_bit = 8
# make following test pass
gates = [xgate, ygate, zgate, rxgate(pi/6), rygate(pi/6), rzgate(pi/6), zxzrot(pi/6, pi/3, pi/6)]
for gate, psii in zip(gates, psi[2:8])
    @test $gate(num_bit, 6)*psi0 == psii
end
cgates = [g|>c for g in gates]
for gate, psii in zip(cgates, psi[9:15])
    @test $gate(num_bit, 6, 4)*psi0 == psii
end
cnccgates = [g|>c|>nc|>c for g in gates]
for gate, psii in zip(cnccgates, psi[16:22])
    @test $gate(num_bit, 6, 2,4,5)*psi0 == psii
end
=#
