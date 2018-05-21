using Compat.Test
using QuCircuit

psi = readdlm("psi-test.dat")
psi = psi[:,1:2:end] + im*psi[:,2:2:end]

# psi[1,:]: psi0
# psi[2:8,:]: (X, Y, Z, Rx(pi/6), Ry(pi/6), Rz(pi/6), Rot(pi/6, pi/3, pi/6))*psi0[6]
# psi[9:15,:]: (C-G↑)*psi0[4,6]
# psi[16:22, :]: (C, NC, C, G↑)*psi0[2,4,5,6]

psi0 = psi[1, :]
count = 2

@testset "check single gates" begin

for each in [
    X(), Y(), Z(),
    rot(:X, pi/6), rot(:Y, pi/6), rot(:Z, pi/6),
    chain(rot(:Z, pi/6), rot(:X, pi/3), rot(:Z, pi/6)),
]

    r = register(psi0, 1)
    c = kron(8, (6, each))
    c(r)
    @test psi[count, :] == vec(state(r))
    count += 1
end
end

@testset "check control" begin

for each in [
    X(), Y(), Z(),
    rot(:X, pi/6), rot(:Y, pi/6), rot(:Z, pi/6),
    chain(rot(:Z, pi/6), rot(:X, pi/3), rot(:Z, pi/6)),
]

    r = register(psi0, 1)
    c = control(8, [4, ], each, 6)
    c(r)
    @test psi[count, :] == vec(state(r))
    count += 1

end

end

# c = kron(8, (6, each))
# c(r)
# @show psi[2, :] == vec(state(r))

# ⊗ = kron
# id = speye(2)
# U = sparse(X())

# mat = id ⊗ id ⊗ id ⊗ U ⊗ id ⊗ id ⊗ id ⊗ id
