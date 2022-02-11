using Test, YaoArrayRegister, BitBasis, YaoBase

function naive_focus!(reg::ArrayReg{B}, bits) where {B}
    nbits = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbits, bits), nbits + 1)
    @views reg.state = reshape(
        permutedims(reshape(reg.state, fill(2, nbits)..., B), norder),
        :,
        (1 << (nbits - length(bits))) * B,
    )
    return reg
end

function naive_relax!(reg::ArrayReg{B}, bits) where {B}
    nbit = nqubits(reg)
    norder = vcat(bits, setdiff(1:nbit, bits), nbit + 1) |> invperm
    @views reg.state =
        reshape(permutedims(reshape(reg.state, fill(2, nbit)..., B), norder), :, B)
    return reg
end


@testset "Focus 1" begin
    reg0 = rand_state(5; nbatch = 3)
    @test focus!(copy(reg0), [1, 4, 2]) == naive_focus!(copy(reg0), [1, 4, 2])
    @test copy(reg0) |>
          focus!(1, 4, 2) |>
          focus!(2) |>
          relax!(2, to_nactive = 3) |>
          relax!(1, 4, 2) == reg0
    reg = focus!(copy(reg0), 2:3)
    @test reg |> probs ≈
          hcat([sum(abs2.(reshape(reg.state[i, :], :, 3)), dims = 1)[1, :] for i = 1:4]...)'
    @test size(state(reg)) == (2^2, 2^3 * 3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3
    @test relax!(reg, 2:3) == reg0
end

@testset "Focus 3" begin
    # conanical shape
    reg = rand_state(3; nbatch = 5)
    @test oneto(reg, 2) |> nactive == 2
    @test reg |> nactive == 3
    @test copy(reg) |> addbits!(2) |> nactive == 5
    reg2 = copy(reg) |> addbits!(2) |> focus!(4, 5)
    @test (measure!(RemoveMeasured(), reg2); reg2) |> relax!(to_nactive = nqubits(reg2)) ≈
          reg

    @test insert_qudits!(copy(reg), 2; nqudits = 2) |> nactive == 5
end

@testset "Focus 2" begin
    reg0 = rand_state(8)
    reg = focus!(copy(reg0), 7)
    @test reg |> probs ≈ sum(abs2.(reg.state), dims = 2)[:, 1]
    @test nactive(reg) == 1

    reg0 = rand_state(10)
    reg = focus!(copy(reg0), 1:8)
    @test hypercubic(reg) == reshape(reg0.state, fill(2, 8)..., 4)
    @test nactive(reg) == 8
    @test reg0 == relax!(reg, 1:8)
end

@testset "focus do ... end" begin
    reg = rand_state(5)
    focus(reg, (1, 2, 3)) do reg
        @test nactive(reg) == 3
    end
    @test nactive(reg) == 5

    reg = rand_state(5)
    focus(reg, 1, 2, 3) do reg
        @test nactive(reg) == 3
    end
    @test nactive(reg) == 5

    reg = rand_state(5)
    focus(reg, 1) do reg
        @test nactive(reg) == 1
    end
    @test nactive(reg) == 5
end

@testset "partial trace" begin
    r = join(ArrayReg(bit"111"), zero_state(1))
    @test partial_tr(r, 1) ≈ ArrayReg(bit"111")
end
