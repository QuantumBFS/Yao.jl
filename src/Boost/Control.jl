function mat(ctrl::ControlBlock{BT, N, T}) where {N, T, BT <: MatrixBlock{1, T}}
    ctrl_vals = @. div(sign(ctrl.ctrl_qubits) + 1, 2)
    controlled_U1(N, mat(ctrl.block), ctrl.ctrl_qubits, ctrl_vals, ctrl.addr)
end
