using Test, Yao

@testset "bag" begin
    bag = Bag(ConstGate.T)
    println(bag)
    reg = zero_state(1)
    @test isenabled(bag)
    @test copy(reg) |> bag ≈ copy(reg) |> ConstGate.T
    @test mat(bag) == mat(ConstGate.T)
    @test !isreflexive(bag)
    @test !ishermitian(bag)
    @test isunitary(bag)
    @test occupied_locs(bag) == (1,)

    # disable it
    disable_block!(bag)
    println(bag)
    @test !isenabled(bag)
    @test copy(reg) |> bag ≈ reg
    @test mat(bag) == mat(I2)
    @test isreflexive(bag)
    @test ishermitian(bag)
    @test isunitary(bag)
    @test occupied_locs(bag) == ()

    # enable and setcontent
    enable_block!(bag)
    println(bag)
    @test !ishermitian(bag)
    setcontent!(bag, Z)
    @test ishermitian(bag)
    @test copy(reg) |> X |> bag ≈ ArrayReg([0im, -1.0])
    @test mat(bag) == mat(Z)
    @test ishermitian(bag)
    @test occupied_locs(bag) == (1,)

    # parameters
    b = Bag(Rx(0.5))
    @test nparameters(b) == length(parameters(b)) == 1
    disable_block!(b)
    @test nparameters(b) == length(parameters(b)) == 0
end
