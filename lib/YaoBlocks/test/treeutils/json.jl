using Test, YaoBlocks, BitBasis, JSON
using YaoBlocks: check_json_roundtrip

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
