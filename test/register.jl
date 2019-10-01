using Test
using YaoSym, YaoArrayRegister, YaoBlocks

@test ket"111" + 2ket"111" == 3ket"111"
@test bra"111" * ket"111" == 1
@test (bra"111" + bra"101") * ket"111" == 1

@test ket"111"^2 == ket"111111"
@test ket"101" * ket"111" == ket"101111"
@test bra"110"^2 == bra"110110"
@test bra"110" * bra"111" == bra"110111"

bra"110"
