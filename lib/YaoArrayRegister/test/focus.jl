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
    norder = invperm(vcat(bits, setdiff(1:nbit, bits), nbit + 1))
    @views reg.state = reshape(
        permutedims(reshape(reg.state, fill(2, nbit)..., B), norder), :, B
    )
    return reg
end

@testset "Focus 1" begin
    reg0 = rand_state(5; nbatch=3)
    @test focus!(copy(reg0), [1, 4, 2]) == naive_focus!(copy(reg0), [1, 4, 2])
    @test relax!(1, 4, 2)(
        relax!(2; to_nactive=3)(focus!(2)(focus!(1, 4, 2)(copy(reg0))))
    ) == reg0
    reg = focus!(copy(reg0), 2:3)
    @test probs(reg) ≈
        hcat([sum(abs2.(reshape(reg.state[i, :], :, 3)); dims=1)[1, :] for i in 1:4]...)'
    @test size(state(reg)) == (2^2, 2^3 * 3)
    @test nactive(reg) == 2
    @test nremain(reg) == 3
    @test relax!(reg, 2:3) == reg0
end

@testset "Focus 3" begin
    # conanical shape
    reg = rand_state(3; nbatch=5)
    @test nactive(oneto(reg, 2)) == 2
    @test nactive(reg) == 3
    @test nactive(addbits!(2)(copy(reg))) == 5
    reg2 = focus!(4, 5)(addbits!(2)(copy(reg)))
    @test relax!(; to_nactive=nqubits(reg2))((measure!(RemoveMeasured(), reg2); reg2)) ≈ reg

    @test nactive(insert_qubits!(copy(reg), 2; nqubits=2)) == 5
end

@testset "Focus 2" begin
    reg0 = rand_state(8)
    reg = focus!(copy(reg0), 7)
    @test probs(reg) ≈ sum(abs2.(reg.state); dims=2)[:, 1]
    @test nactive(reg) == 1

    reg0 = rand_state(10)
    reg = focus!(copy(reg0), 1:8)
    @test hypercubic(reg) == reshape(reg0.state, fill(2, 8)..., 4)
    @test nactive(reg) == 8
    @test reg0 == relax!(reg, 1:8)

    reg1 = focus!(copy(reg0), (5, 3, 2)) do reg
        @test nactive(reg) == 3
        reg
    end

    @test reg1 == reg0
    @test reg0 == relax!(7, 3, 2)(focus!(7, 3, 2)(copy(reg0)))
end

@testset "partial trace" begin
    r = join(ArrayReg(bit"111"), zero_state(1))
    @test partial_tr(r, 1) ≈ ArrayReg(bit"111")
end
