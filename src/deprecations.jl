import YaoArrayRegister: ArrayReg
@deprecate ArrayReg(bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch())  arrayreg(ComplexF64, bitstr; nbatch=nbatch)
@deprecate addbits! append_qudits!
@deprecate insert_qudits!(reg::AbstractRegister, loc::Int; nqudits) insert_qudits!(reg, loc, nqudits)
@deprecate insert_qubits!(reg::AbstractRegister, loc::Int; nqubits) insert_qubits!(reg, loc, nqubits)
