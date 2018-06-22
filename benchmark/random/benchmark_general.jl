using BenchmarkTools
nbit=16
Cb = control(nbit, (3,), 5=>X)
Pb = PutBlock{nbit}(CNOT, (3, 5))
@benchmark apply!($(copy(Reg)), $Cb)
@benchmark apply!($(copy(Reg)), $Pb)

