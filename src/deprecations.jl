import YaoArrayRegister: ArrayReg
@deprecate ArrayReg(bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch())  arrayreg(ComplexF64, bitstr; nbatch=nbatch)
@deprecate addbits! append_qudits!
