using Compat.Test
using QuCircuit
import QuCircuit: KronBlock
# Block Trait
import QuCircuit: nqubit, ninput, noutput, isunitary, ispure
# Required Methods
import QuCircuit: apply!, dispatch!

@testset "check sparse" begin

GateSet = [
    X(), Y(), Z(),
    phase(0.1), phase(0.2), phase(0.3),
    rot(:X, 0.1), rot(:Y, 0.4), rot(:Z, 0.2)
]

⊗ = kron
U = sparse(X())
id = speye(2)

@testset "case 1" begin
    mat = id ⊗ U
    g = KronBlock{2}(1=>X())
    @test mat == sparse(g)

    mat = U ⊗ id
    g = KronBlock{2}(2=>X())
    @test mat == sparse(g)
end

@testset "case 2" begin
    mat = sparse(X()) ⊗ sparse(Y()) ⊗ sparse(Z())
    g = KronBlock{3}(1=>Z(), 2=>Y(), 3=>X())
    @test mat == sparse(g)

    mat = id ⊗ mat
    g = KronBlock{4}(1=>Z(), 2=>Y(), 3=>X())
    @test mat == sparse(g)
end

@testset "random dense sequence" begin

function random_dense_kron(n)
    addrs = randperm(n)
    blocks = [(i, rand(GateSet)) for i in addrs]
    g = KronBlock{n}(blocks...)
    sorted_blocks = sort(blocks, by=x->x[1])
    t = mapreduce(x->sparse(x[2]), kron, speye(1), reverse(sorted_blocks))
    sparse(g) ≈ t || info(g)
end

    for i = 2:8
        @test random_dense_kron(i)
    end
end

@testset "random sparse sequence" begin

function rand_kron_test(n)
    firstn = rand(1:n)
    addrs = randperm(n)
    blocks = [rand(GateSet) for i = 1:firstn]
    seq = [(i, each) for (i, each) in zip(addrs[1:firstn], blocks)]
    mats = [(i, sparse(each)) for (i, each) in zip(addrs[1:firstn], blocks)]
    append!(mats, [(i, speye(2)) for i in addrs[firstn+1:end]])
    sorted = sort(mats, by=x->x[1])
    mats = map(x->x[2], reverse(sorted))

    g = KronBlock{n}(seq...)
    t = reduce(kron, speye(1), mats)
    sparse(g) ≈ t || info(g)
end

for i = 4:8
    @test rand_kron_test(i)
end

end

end
