using Test
using YaoSym, YaoArrayRegister, YaoBlocks

@test ket"111" + 2ket"111" == 3ket"111"
@test bra"111" * ket"111" == 1
@test (bra"111" + bra"101") * ket"111" == 1
