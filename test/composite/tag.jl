using Test, YaoBlocks

struct MockedTag{BT, N} <: TagBlock{BT, N}
    content::BT

    MockedTag(x::BT) where {N, BT <: AbstractBlock{N}} = new{BT, N}(x)
end

@test nqubits(MockedTag(X)) == nqubits(X)
@test nqubits(MockedTag(kron(X, Y))) == nqubits(kron(X, Y))

@test getiparams(MockedTag(phase(0.1))) == ()
@test getiparams(MockedTag(cache(phase(0.1)))) == ()
@test getiparams(MockedTag(Rx(0.1))) == ()

@test parameters(MockedTag(phase(0.1))) == [0.1]
@test parameters(MockedTag(cache(phase(0.1)))) == [0.1]
@test parameters(MockedTag(Rx(0.1))) == [0.1]

@test occupied_locs(MockedTag(chain(3, put(1=>X), put(3=>X)))) == occupied_locs(chain(3, put(1=>X), put(3=>X)))
