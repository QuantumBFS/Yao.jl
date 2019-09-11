using Test, YaoSym

@test_broken bra"111" + bra"111" == 2 * bra"111"

@test bra"110" + bra"111" == (ket"110" + ket"111")'

@test bra"110" * bra"111" == bra"110111"
@test ket"110" * ket"111" == ket"110111"

@test bra"110" * ket"110" == 1
@test bra"10" * ket"10110" == ket"110"

ket"101" * bra"111"

collect(ket"101")
