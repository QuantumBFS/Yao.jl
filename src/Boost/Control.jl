function mat(ctrl::ControlBlock{N, BT, C, T}) where {N, T, C, BT <: MatrixBlock{1, T}}
    controlled_U1(N, mat(ctrl.block), [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addr)
end
