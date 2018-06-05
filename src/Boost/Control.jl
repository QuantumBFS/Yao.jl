function mat(ctrl::ControlBlock{BT, N, T}) where {N, T, BT <: MatrixBlock{1, T}}
    controlled_U1(N, mat(ctrl.block), ctrl.ctrl_qubits, ctrl.addr)
end
