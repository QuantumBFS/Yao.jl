using Yao
using Yao.Blocks
using Compat.Test
using Yao.LuxurySparse
using Yao.LuxurySparse:I

⊗ = kron
function hilbertkron(num_bit::Int, gates::Vector{T}, locs::Vector{Int}) where T<:AbstractMatrix
    locs = num_bit - locs + 1
    order = sortperm(locs)
    _wrap_identity(gates[order], diff(vcat([0], locs[order], [num_bit+1])) - 1)
end

# kron, and wrap matrices with identities.
function _wrap_identity(data_list::Vector{T}, num_bit_list::Vector{Int}) where T<:AbstractMatrix
    length(num_bit_list) == length(data_list) + 1 || throw(ArgumentError())
    reduce((x,y)->x ⊗ y[1] ⊗ I(1<<y[2]), I(1 << num_bit_list[1]), zip(data_list, num_bit_list[2:end]))
end

####################### Controlled Gates #######################
general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} = I(1<<num_bit) - hilbertkron(num_bit, projectors, cbits) + hilbertkron(num_bit, vcat(projectors, gates), vcat(cbits, locs))
rotgate(gate::AbstractMatrix, θ::Real) = expm(-0.5im*θ*Matrix(gate))


xg = XGate{Complex128}()
yg = YGate{Complex128}()
zg = ZGate{Complex128}()
hg = HGate{Complex128}()
p0 = mat(P0)
p1 = mat(P1)
gate_list = [xg, yg, zg, hg]

num_bit = 6
@testset "Single Qubit" begin
    for gg in gate_list
        @test mat(KronBlock{num_bit, Complex128}([3], [gg])) ≈ hilbertkron(num_bit, [mat(gg)], [3])
    end
end

@testset "Single Control Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{6}([4], gg, 3)) == general_controlled_gates(num_bit, [p1], [4],  [mat(gg)], [3])
    end
end

@testset "Multiple Control Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{6}([4,2], gg, 3)) == general_controlled_gates(num_bit, [p1, p1], [4,2],  [mat(gg)], [3])
    end
end

@testset "Rotation Gates" begin
    for gg in gate_list
        @test mat(KronBlock{num_bit, Complex128}([3], [RotationGate(gg, π/8)])) ≈ hilbertkron(num_bit, [rotgate(mat(gg), π/8)], [3])
    end
end

@testset "Single-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{num_bit}([4], RotationGate(gg, π/8), 3)) ≈ general_controlled_gates(num_bit, [p1], [4], [rotgate(mat(gg), π/8)], [3])
    end
end

@testset "Multi-Controlled Rotation Gates" begin
    for gg in gate_list
        @test mat(ControlBlock{num_bit}([4,2], RotationGate(gg, π/8), 3)) ≈ general_controlled_gates(num_bit, [p1, p1], [4, 2], [rotgate(mat(gg), π/8)], [3])
    end
end
