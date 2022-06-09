using YaoPlots
using Compose
using Test
using Yao

@testset "gate styles" begin
    c = YaoPlots.CircuitGrid(1)
	@test YaoPlots.get_brush_texts(c, X)[2] == "X"
	@test YaoPlots.get_brush_texts(c, Rx(0.5))[2] == "Rx(0.5)"
	@test YaoPlots.get_brush_texts(c, shift(0.5))[2] == "ϕ(0.5)"
	@test YaoPlots.get_brush_texts(c, YaoBlocks.phase(0.5))[2] == "    0.5\n"
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
		put(3=>X) >> c
		put(3=>matblock(rand_unitary(2); tag="xxx")) >> c
		put(3=>igate(1)) >> c
		time_evolve(put(3,3=>igate(1)), 0.1) >> c
		control(2, 3=>X) >> c
		control(2, 3=>shift(0.5)) >> c
		chain(5, control(2, 3=>X), put(1=>X)) >> c
		@test YaoPlots.depth(c) >= 6
	end
	@test gg isa Context

	g = put(5, (3, 4)=>SWAP) |> vizcircuit(; scale=0.7, w_line=0.8, w_depth=0.9)
	@test g isa Context
	@test vizcircuit(put(5, (3,4)=>kron(X, Y)); scale=0.7, w_line=0.8, w_depth=0.9) isa Context

	@test vizcircuit(control(10, (2, -3), 6=>X)) isa Context
	@test vizcircuit(control(10, (2, -3), 6=>im*X)) isa Context
	@test plot(put(7, (2,3)=>matblock(randn(4,4)))) isa Context
    # qudit
    @test vizcircuit(put(10, 6=>matblock(rand_unitary(3); nlevel=3, tag="3 level"))) isa Context
end

@testset "fix #3" begin
	@test (control(4, 2, (1,3)=>kron(X, X)) |> vizcircuit) isa Context
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
    YaoPlots.CircuitStyles.lw[] = 2.5pt
    YaoPlots.CircuitStyles.textsize[] = 13pt
    YaoPlots.CircuitStyles.paramtextsize[] = 8pt
            
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Compose.Context
    darktheme!()
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Compose.Context
    lighttheme!()
    @test plot(chain(3, put(1=>X), repeat(3, H), put(2=>Y), repeat(3, Rx(π/2)))) isa Compose.Context
end
