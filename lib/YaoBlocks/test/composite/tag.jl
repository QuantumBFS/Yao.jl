using Test, YaoBlocks, YaoArrayRegister
using YaoAPI, BitBasis

struct MockedTag{BT,D} <: TagBlock{BT,D}
    content::BT

    MockedTag(x::BT) where {D,BT<:AbstractBlock{D}} = new{BT,D}(x)
end

@test nqubits(MockedTag(X)) == nqubits(X)
@test nqubits(MockedTag(kron(X, Y))) == nqubits(kron(X, Y))

@test getiparams(MockedTag(phase(0.1))) == ()
@test getiparams(MockedTag(cache(phase(0.1)))) == ()
@test getiparams(MockedTag(Rx(0.1))) == ()

@test parameters(MockedTag(phase(0.1))) == [0.1]
@test parameters(MockedTag(cache(phase(0.1)))) == [0.1]
@test parameters(MockedTag(Rx(0.1))) == [0.1]

@test occupied_locs(MockedTag(chain(3, put(1 => X), put(3 => X)))) ==
      occupied_locs(chain(3, put(1 => X), put(3 => X)))

@testset "scale apply" begin
    # factor
    @test factor(-X) == -1
    @test factor(-2 * X) == -2

    # type
    @test -X isa Scale{<:Val}
    @test -im * X isa Scale{<:Number}
    @test Val(-im) * X isa Scale{<:Val}
    @test -2 * X isa Scale{<:Number}

    # apply!
    reg = rand_state(1)
    @test apply!(copy(reg), -X) ≈ -apply!(copy(reg), X)
    @test apply!(copy(reg), (Val(-im) * Y)') ≈ apply!(copy(reg), im * Y)
    @test apply!(copy(reg), (-2im * Y)') ≈ apply!(copy(reg), 2im * Y)

    # mat
    @test mat(-X) ≈ -mat(X)
    @test mat((Val(-im) * Y)') ≈ (-im * mat(Y))'
    @test mat((-2im * Y)') ≈ (-2im * mat(Y))'

    # other
    @test chsubblocks(-X, Y) == -Y
    @test cache_key(Scale(Val(-1), X)) == cache_key(Scale(-1, X))
    @test copy(-X) == -X
    @test copy(-X) isa Scale{<:Val}

    # parameters
    @test getiparams(2X) == (2,)
    @test setiparams(2X, 4.0) == 4.0X
    s = 2.0X
    setiparams!(s, 4.0)
    @test s == 4.0X
end

@testset "properties" begin
    xg = put(100, 3 => X)
    yg = put(100, 3 => Y)
    yg = put(100, 3 => Y)
    @test_throws Exception !ishermitian(im * xg)
    @test ishermitian(3 * xg)
    @test_throws Exception !isreflexive(im * xg)
    @test isreflexive(-1 * xg)
    @test isunitary(im * xg)
    @test_throws Exception !isunitary(2 * xg)
    @test !iscommute(2 * xg, 2 * yg)
    @test iscommute(2 * xg, 2 * xg)
end

@testset "daggered" begin
    dg = Daggered(ConstGate.T)
    @test dg isa Daggered
    @test apply!(product_state(bit"1"), dg) ≈ apply!(product_state(bit"1"), ConstGate.Tdag)
    @test chsubblocks(dg, X) == Daggered(X)
end

@testset "instruct_get_element: dagger, scale" begin
    for pb in [3*put(3, 2=>2*matblock(rand_unitary(2)))', Val(2) * Daggered(put(4, (4,2)=>-matblock(rand_unitary(9); nlevel=3)))]
        mpb = mat(pb)
        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= pb[i, j] == mpb[Int(i)+1, Int(j)+1]
        end
        @test allpass

        allpass = true
        for i=basis(pb), j=basis(pb)
            allpass &= vec(pb[:, j]) == mpb[:, Int(j)+1]
            allpass &= isclean(pb[:,j])
        end
        @test allpass
    end
end

@testset "density matrix" begin
    reg = rand_state(3)
    r = density_matrix(reg)
    @test density_matrix(apply(reg, 2*put(3, 2=>X))) ≈ apply(r, 2*put(3, 2=>X))
end