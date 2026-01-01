using Test, YaoBlocks, BitBasis, JSON
using YaoBlocks: check_dumpload, check_json_roundtrip

@testset "YaoScript format - check_dumpload" begin
    @test check_dumpload(X)
    @test check_dumpload(X + Y)
    @test check_dumpload(+(put(5, 4 => X), put(5, 5 => X)))
    @test check_dumpload(kron(put(1, 1 => X), Y))
    @test check_dumpload(kron(5, 2 => X, 4 => Y))
    @test check_dumpload(shift(0.5))
    @test check_dumpload(phase(0.5))
    @test check_dumpload(time_evolve(X, 0.5))
    @test check_dumpload(put(5, 2 => X))
    @test check_dumpload(chain(put(5, 2 => X)))
    @test check_dumpload(put(5, 2 => rot(X, 0.5)))
    @test check_dumpload(control(5, 1, 2 => rot(X, 0.5)))
    @test check_dumpload(control(5, (1, -4), 2 => rot(X, 0.5)))
    @test check_dumpload(subroutine(5, rot(SWAP, 0.5), (2, 5)))
    @test check_dumpload(repeat(5, put(1, 1 => X), (2, 5)))
    @test check_dumpload(Measure(5))
    @test check_dumpload(Measure(5, operator = put(5, 2 => X)))
    @test check_dumpload(Measure(5, locs = (3, 1), resetto = bit"01"))
    @test check_dumpload(
        Measure(5, locs = (3, 2), operator = put(2, 2 => X), resetto = bit"11"),
    )
    @test check_dumpload(Daggered(X))
    @test check_dumpload(2 * X)
    @test check_dumpload(cache(2 * X))
    @test_throws ErrorException check_dumpload(kron(5, 2:3 => SWAP))

    block_A(i, j) = control(i, j => shift(2π / (1 << (i - j + 1))))
    block_B(n, i) = chain(n, i == j ? put(i => H) : block_A(j, i) for j = i:n)
    qft(n) = chain(block_B(n, i) for i = 1:n)
    @test check_dumpload(qft(5))
end

@testset "YaoScript format - yao macro" begin
    c = yao"""
    let nqubits = 5
        3 => rot(X, 0.3)
        2 => X
    end
    """
    c2 = @yaoscript let nqubits = 5
        3 => rot(X, 0.3)
        2 => X
    end

    y = chain(5, put(3 => rot(X, 0.3)), put(2 => X))
    @test c == y
    @test c == c2
    @test check_dumpload(y)
    yaotofile("_test.yao", y)
    yy = @eval $(yaofromfile("_test.yao"))
    @test y == yy
    rm("_test.yao")

    g = eval(yaofromfile(joinpath(dirname(@__FILE__), "yaoscript.yao")))
    s = string(yaotoscript(g))
    g1 = eval(yaofromstring(s))
    @test g == g1
end

@testset "JSON instruction format - basic gates" begin
    # Single qubit gates
    c = chain(3, put(1 => X), put(2 => Y), put(3 => Z))
    @test check_json_roundtrip(c)
    
    # Hadamard
    c = chain(2, put(1 => H), put(2 => H))
    @test check_json_roundtrip(c)
    
    # T gate
    c = chain(2, put(1 => T))
    @test check_json_roundtrip(c)
end

@testset "JSON instruction format - rotation gates" begin
    c = chain(3, put(1 => Rx(0.5)), put(2 => Ry(0.3)), put(3 => Rz(0.1)))
    @test check_json_roundtrip(c)
end

@testset "JSON instruction format - controlled gates" begin
    # CNOT
    c = chain(2, control(2, 1, 2 => X))
    @test check_json_roundtrip(c)
    
    # CZ
    c = chain(2, control(2, 1, 2 => Z))
    @test check_json_roundtrip(c)
    
    # Toffoli (CCX)
    c = chain(3, control(3, (1, 2), 3 => X))
    @test check_json_roundtrip(c)
    
    # Controlled rotation
    c = chain(3, control(3, 1, 2 => Rz(0.5)))
    @test check_json_roundtrip(c)
end

@testset "JSON instruction format - measurement" begin
    # Test that measurement serializes correctly (can't compare with mat for Measure)
    c = chain(3, put(1 => H), Measure(3; locs=(1,)))
    d = circuit_to_json_dict(c)
    @test d["instructions"][2]["name"] == "measure"
    @test d["instructions"][2]["qubits"] == [0]  # 0-indexed
    
    c = chain(2, put(1 => H), put(2 => X), Measure(2))
    d = circuit_to_json_dict(c)
    @test d["instructions"][3]["name"] == "measure"
    @test d["instructions"][3]["qubits"] == [0, 1]
end

@testset "JSON instruction format - file I/O" begin
    c = chain(3, put(1 => H), control(3, 1, 2 => X), put(3 => Rz(0.5)))
    
    json_to_file("_test.json", c)
    c2 = json_from_file("_test.json")
    @test mat(c) ≈ mat(c2)
    rm("_test.json")
end

@testset "JSON instruction format - dict structure" begin
    c = chain(2, put(1 => H), control(2, 1, 2 => X))
    d = circuit_to_json_dict(c)
    
    @test d["version"] == "1.0"
    @test d["nqubits"] == 2
    @test length(d["instructions"]) == 2
    
    # Check H gate
    @test d["instructions"][1]["name"] == "h"
    @test d["instructions"][1]["qubits"] == [0]
    
    # Check CNOT
    @test d["instructions"][2]["name"] == "cx"
    @test d["instructions"][2]["qubits"] == [0, 1]
end

@testset "JSON instruction format - shift and phase gates" begin
    c = chain(2, put(1 => shift(0.5)))
    @test check_json_roundtrip(c)
    
    c = chain(2, control(2, 1, 2 => shift(0.3)))
    @test check_json_roundtrip(c)
end
