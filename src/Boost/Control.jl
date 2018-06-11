function mat(ctrl::ControlBlock{N, <:MatrixBlock{1, T}, C, T}) where {N, T, C}
    println("calling controlled_U1")
    controlled_U1(N, mat(ctrl.block), [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addr)
end
