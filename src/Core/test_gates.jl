using Compat.Test
include("gates.jl")

@testset "basic gate" begin
    # check matrixes
    for (gate, MAT) in [
        (xgate, [0 1;1 0]),
        (ygate, [0 -im; im 0]),
        (zgate, [1 0; 0 -1]),
        #(hgate, (elem = 1 / sqrt(2); [elem elem; elem -elem])),
    ]
        println(gate(1, basis(1)))
        @test full(gate(1, basis(1))) == MAT
    end
end

# psi0
# ['sx', 'sy', 'sz', 'rx(np.pi/6)', 'ry(np.pi/6)', 'rz(np.pi/6)', 'rot(np.pi/6, np.pi/3, np.pi/6)'] apply on 6
# above gates controled by c(4)
# above gates controled by c(2)nc(4)c(5)
psi = loadldm("psi-test.jl")
psi = psi[:, 1:2:end] + im * psi[:, 2:2:end]
psi0 = psi[1,:]
basis = collect(1:1<<num_bit)
num_bit = 8
# make following test pass
gates = [xgate, ygate, zgate, rxgate(pi/6), rygate(pi/6), rzgate(pi/6), zxzrot(pi/6, pi/3, pi/6)]
for gate, psii in zip(gates, psi[2:8])
    @test $gate(6, basis)*psi0 == psii
end
cgates = [g|>c for g in gates]
for gate, psii in zip(cgates, psi[9:15])
    @test $gate(6, 4, basis)*psi0 == psii
end
cnccgates = [g|>c|>nc|>c for g in gates]
for gate, psii in zip(cnccgates, psi[16:22])
    @test $gate(6, 2,4,5, basis)*psi0 == psii
end
