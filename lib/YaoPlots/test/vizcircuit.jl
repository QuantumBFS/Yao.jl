using YaoPlots
using Test
using YaoBlocks
using YaoPlots: addblock!, CircuitGrid, circuit_canvas
using YaoArrayRegister
using Luxor

@testset "gate styles" begin
    c = YaoPlots.CircuitGrid(1)
    @test YaoPlots.get_brush_texts(c, X)[2] == "X"
    @test YaoPlots.get_brush_texts(c, Rx(0.5))[2] == "Rx(0.5)"
    @test YaoPlots.get_brush_texts(c, shift(0.5))[2] == "φ(0.5)"
    @test YaoPlots.get_brush_texts(c, YaoBlocks.phase(0.5))[2] == ""
end

@testset "circuit canvas" begin
    c = CircuitGrid(5)
    @test YaoPlots.nline(c) == 5
    @test YaoPlots.frontier(c, 2, 3) == 0
    @test YaoPlots.depth(c) == 0
    circuit_canvas(5) do c
        YaoPlots.draw!(c, put(5, 3=>X), 1:5, [])
        @test YaoPlots.frontier(c, 1, 2) == 0
        @test YaoPlots.frontier(c, 3, 5) == 1
        @test YaoPlots.depth(c) == 1
    end

    gg = circuit_canvas(5) do c
        addblock!(c, put(3=>X))
        addblock!(c, put(3=>matblock(rand_unitary(2); tag="xxx")))
        addblock!(c, put(3=>igate(1)))
        addblock!(c, time_evolve(put(3,3=>igate(1)), 0.1))
        addblock!(c, control(2, 3=>X))
        addblock!(c, control(2, 3=>shift(0.5)))
        addblock!(c, chain(5, control(2, 3=>X), put(1=>X)))
        @test YaoPlots.depth(c) >= 6
    end
    @test gg isa Drawing

    g = put(5, (3, 4)=>SWAP) |> vizcircuit(; w_line=0.8, w_depth=0.9)
    @test g isa Drawing
    @test vizcircuit(put(5, (3,4)=>kron(X, Y)); w_line=0.8, w_depth=0.9) isa Drawing

    @test vizcircuit(control(10, (2, -3), 6=>X)) isa Drawing
    @test vizcircuit(control(10, (2, -3), 6=>im*X)) isa Drawing
    @test plot(put(7, (2,3)=>matblock(randn(4,4)))) isa Drawing
    # qudit
    @test vizcircuit(put(10, 6=>matblock(rand_unitary(3); nlevel=3, tag="3 level"))) isa Drawing
end

@testset "fix #3" begin
    @test (control(4, 2, (1,3)=>kron(X, X)) |> vizcircuit) isa Drawing
end

@testset "pretty_angle" begin
    @test YaoPlots.pretty_angle(π) == "π"
    @test YaoPlots.pretty_angle(π*1.0) == "π"
    @test YaoPlots.pretty_angle(-π*1.0) == "-π"
    @test YaoPlots.pretty_angle(-π*0.0) == "0"
    @test YaoPlots.pretty_angle(-π*0.5) == "-π/2"
    @test YaoPlots.pretty_angle(1.411110) == "1.41"
end

@testset "readme" begin
    YaoPlots.CircuitStyles.linecolor[] = "pink" 
    YaoPlots.CircuitStyles.gate_bgcolor[] = "yellow" 
    YaoPlots.CircuitStyles.textcolor[] = "#000080" # the navy blue color
    YaoPlots.CircuitStyles.fontfamily[] = "JuliaMono"
    YaoPlots.CircuitStyles.lw[] = 2.5
    YaoPlots.CircuitStyles.textsize[] = 13
    YaoPlots.CircuitStyles.paramtextsize[] = 8
            
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Drawing
    darktheme!()
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Drawing
    lighttheme!()
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Drawing
end

@testset "readme" begin
    circuit = chain(
        4,    
        kron(X, H, H, H),
        kron(1=>Y, 4=>H), 
        put(2=>Y),
    )
    YaoPlots.CircuitStyles.barrier_for_chain[] = true
    @test vizcircuit(circuit) isa Drawing
end

@testset "rot igate" begin
    @test plot(rot(igate(1), 1.)) isa Drawing
    @test plot(rot(put(3, 1=>X), 1.)) isa Drawing
end

@testset "issue 558" begin
    qc = chain(2)
    push!(qc,put(2,1 => Measure(1)))
    push!(qc,put(2,2 => Measure(1)))
    @test vizcircuit(qc) isa Drawing
end


@testset "noise channel" begin
    c1 = quantum_channel(DepolarizingError(1, 0.1))
    c2 = quantum_channel(PhaseFlipError(0.1))
    c3 = quantum_channel(AmplitudeDampingError(0.1))
    c4 = SuperOp(quantum_channel(ResetError(0.1, 0.0)))
    grid = CircuitGrid(2)
    @test YaoPlots.get_brush_texts(grid, c1) == (grid.gatestyles.g, "DEP(0.1)")
    @test YaoPlots.get_brush_texts(grid, c2) == (grid.gatestyles.g, "MU(0.9*I2, 0.1*Z)")
    @test YaoPlots.get_brush_texts(grid, c3) == (grid.gatestyles.g, "KR(A0, A1)")
    @test YaoPlots.get_brush_texts(grid, c4) == (grid.gatestyles.g, "CHN")

    circuit = chain(
        2,
        put(1=>c1),
        put(2=>c2),
        put(2=>c3),
        put(2=>c4),
    )
    @test plot(circuit) isa Drawing
end

@testset "fix #563 - measure" begin
    c = chain(5, Measure(5; locs=(2,), error_prob=0.1, operator=X))
    res = vizcircuit(c)
    @test res isa Drawing
    display(res)
    res = vizcircuit(depolarizing_channel(2, p=0.2))
    @test res isa Drawing
    display(res)
    res = vizcircuit(put(2, 1=>addlabel(X; name="X", toptext="rec[1]\n3", bottomtext="p = 0.01")))
    @test res isa Drawing
    display(res)
end

@testset "color_to_hex" begin
    # Test transparent
    @test YaoPlots.CircuitStyles.color_to_hex("transparent") == "#00000000"
    
    # Test hex codes stay as-is
    @test YaoPlots.CircuitStyles.color_to_hex("#FF0000") == "#FF0000"
    @test YaoPlots.CircuitStyles.color_to_hex("#000000") == "#000000"
    @test YaoPlots.CircuitStyles.color_to_hex("#FFFFFF") == "#FFFFFF"
    
    # Test color names get converted to hex
    @test YaoPlots.CircuitStyles.color_to_hex("red") == "#FF0000"
    @test YaoPlots.CircuitStyles.color_to_hex("black") == "#000000"
    @test YaoPlots.CircuitStyles.color_to_hex("white") == "#FFFFFF"
    @test YaoPlots.CircuitStyles.color_to_hex("pink") == "#FFC0CB"
    @test YaoPlots.CircuitStyles.color_to_hex("yellow") == "#FFFF00"
    @test YaoPlots.CircuitStyles.color_to_hex("blue") == "#0000FF"
    @test YaoPlots.CircuitStyles.color_to_hex("green") == "#008000"
    
    # Test case insensitivity
    @test YaoPlots.CircuitStyles.color_to_hex("Red") == "#FF0000"
    @test YaoPlots.CircuitStyles.color_to_hex("RED") == "#FF0000"
end

@testset "JSON backend" begin
    # Helper function to check if text exists in loc_brush_texts
    function has_text_in_gate(cmd, text)
        if get(cmd, "type", "") != "gate"
            return false
        end
        loc_brush_texts = get(cmd, "loc_brush_texts", [])
        return any(lbt -> contains(get(lbt, "text", ""), text), loc_brush_texts)
    end
    
    # Test basic single qubit gate
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(3, put(2=>X))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test length(result) > 0
    @test isfile(temp_file)  # Should be automatically saved
    rm(temp_file)
    
    # Check for gate commands with X gate
    gate_found = any(d -> get(d, "type", "") == "gate", result)
    x_found = any(d -> has_text_in_gate(d, "X"), result)
    @test gate_found
    @test x_found
    
    # Test with rotation gates
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(3, put(1=>Rx(π/2)), put(2=>Ry(π/4)))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> has_text_in_gate(d, "Rx"), result)
    @test any(d -> has_text_in_gate(d, "Ry"), result)
    rm(temp_file)
    
    # Test with control gates
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = control(3, 1, 2=>X)
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    # Check for gate command
    @test any(d -> get(d, "type", "") == "gate", result)
    rm(temp_file)
    
    # Test with SWAP gate
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = put(3, (1,2)=>SWAP)
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> get(d, "type", "") == "gate", result)
    rm(temp_file)
    
    # Test with phase gate
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(2, put(1=>YaoBlocks.phase(π/4)))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> get(d, "type", "") == "gate", result)
    rm(temp_file)
    
    # Test with measure
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(3, put(1=>Measure(1)))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> get(d, "type", "") == "gate", result)
    rm(temp_file)
    
    # Test with noise channel (depolarizing)
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(2, put(1=>quantum_channel(DepolarizingError(1, 0.1))))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> has_text_in_gate(d, "DEP"), result)
    rm(temp_file)
    
    # Test with control block and negative control
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = control(4, (1, -2), 3=>X)
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    # Should have gate commands
    @test any(d -> get(d, "type", "") == "gate", result)
    rm(temp_file)
    
    # Test complex circuit
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(
        4,
        kron(X, H, H, H),
        control(4, 1, 2=>X),
        put(4, 2=>Rx(π/2)),
        put(4, (2,3)=>SWAP),
        put(4, 1=>Measure(1))
    )
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test length(result) > 0  # Should have gate commands
    
    # Verify JSON structure for gate commands
    gate_cmd = findfirst(d -> get(d, "type", "") == "gate", result)
    @test gate_cmd !== nothing
    cmd = result[gate_cmd]
    @test haskey(cmd, "type")
    @test haskey(cmd, "loc_brush_texts")
    @test cmd["loc_brush_texts"] isa Vector
    
    # Check structure of loc_brush_texts
    if !isempty(cmd["loc_brush_texts"])
        lbt = cmd["loc_brush_texts"][1]
        @test haskey(lbt, "qubits")
        @test haskey(lbt, "brush")
        @test haskey(lbt, "text")
        @test lbt["qubits"] isa Vector
        @test lbt["text"] isa String
    end
    rm(temp_file)
    
    # Test with labeled blocks
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = put(2, 1=>addlabel(X; name="MyGate", toptext="top", bottomtext="bottom"))
    result = vizcircuit(circuit; backend=backend)
    @test result isa Vector{Dict}
    @test any(d -> has_text_in_gate(d, "MyGate"), result)
    rm(temp_file)
    
    # Test save functionality and read back
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file)
    circuit = chain(2, put(1=>X), put(2=>H))
    vizcircuit(circuit; backend=backend)
    
    # File should be automatically saved
    @test isfile(temp_file)
    
    # Read back and verify
    using JSON3
    read_back = JSON3.read(read(temp_file, String))
    @test length(read_back) == length(backend.draw_commands)
    @test read_back[1]["type"] == backend.draw_commands[1]["type"]
    
    # Clean up
    rm(temp_file)
    
    # Test automatic save with pretty=false
    temp_file = tempname() * ".json"
    backend = YaoPlots.CircuitStyles.JSONBackend(temp_file, pretty=false)
    vizcircuit(chain(2, put(1=>H)); backend=backend)
    @test isfile(temp_file)
    
    # Verify compact format (no newlines except at end)
    content = read(temp_file, String)
    @test count('\n', content) <= 1
    
    # Clean up
    rm(temp_file)
end