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