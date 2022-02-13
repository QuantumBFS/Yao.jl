@deprecate insert_qubits!(args...; kwargs...) insert_qudits!(args...; kwargs...)
@deprecate ArrayReg(bitstr::BitStr; nbatch::Union{Int,NoBatch}=NoBatch())  arrayreg(ComplexF64, bitstr; nbatch=nbatch)
