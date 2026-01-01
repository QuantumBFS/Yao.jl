using Test, YaoBlocks, YaoBlocks.ConstGate

@testset "primitive blocks" begin
    @test qasm(I2) == "id"
    @test qasm(X) == "x"
    @test qasm(Y) == "y"
    @test qasm(Z) == "z"
    @test qasm(S) == "s"
    @test qasm(T) == "t"
    @test qasm(Sdag) == "inv @ s"
    @test qasm(Tdag) == "inv @ t"
    @test qasm(Rx(0.7)) == "rx(0.7)"
    @test qasm(Ry(0.7)) == "ry(0.7)"
    @test qasm(Rz(0.7)) == "rz(0.7)"

    # customized gate
    @test qasm(matblock(rand_unitary(4); tag="zz")) == "zz"

    # phase gate
    @test qasm(shift(0.7)) == "p(0.7)"

    # undefined gate
    @const_gate UU = rand_unitary(4)
    @test_throws ErrorException qasm(UU)
end

@testset "put block" begin
    # note qubit index of OpenQASM is 0-based
    @test qasm(put(6, 5=>X)) == "x reg[4]"
end

@testset "control block" begin
    @test qasm(control(6, 3, 5=>X)) == "ctrl @ x reg[2], reg[4]"
    @test qasm(control(6, -3, 5=>X)) == "negctrl @ x reg[2], reg[4]"
    @test qasm(control(6, (-3, 2), 5=>X)) == "negctrl @ ctrl @ x reg[2], reg[1], reg[4]"

    # cphase
    @test qasm(control(6, (-3, 2), 5=>shift(0.5))) == "negctrl @ ctrl @ p(0.5) reg[2], reg[1], reg[4]"
end

@testset "chain block" begin
    @test qasm(chain(put(6, 5=>X))) == "x reg[4]"
    @test qasm(chain(put(6, 5=>X), put(6, 3=>X))) == "x reg[4];\nx reg[2]"
    expected = "OPENQASM 3.0;\ninclude \"qelib1.inc\";\nqreg q[6];\nx reg[4];\nx reg[2]"
    @test qasm(chain(put(6, 5=>X), put(6, 3=>X)); include_header=true) == expected
    @test_throws AssertionError qasm(chain(X, Y))
end

@testset "dagger block" begin
    @test qasm(Daggered(put(6, 5=>X))) == "inv @ x reg[4]"
end
