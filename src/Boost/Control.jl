function mat(ctrl::ControlBlock{N, <:MatrixBlock{1}, C, 1}) where {N, C}
    controlled_U1(N, mat(ctrl.block), [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addrs...)
end

for (GATE, APPLY, MAT) in zip([:XGate, :YGate, :ZGate], [:cxapply!, :cyapply!, :czapply!], [:cxgate, :cygate, :czgate])
    @eval function mat(ctrl::ControlBlock{N, <:$GATE, C, 1, T}) where {N, C, T}
        $MAT(T, N, [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addrs...)
    end
    @eval function apply!(reg::DefaultRegister, ctrl::ControlBlock{N, <:$GATE, 1, 1, T}) where {N, T}
        state = reg.state |> matvec
        $APPLY(state, ctrl.ctrl_qubits..., ctrl.vals..., ctrl.addrs...)
        reg
    end
end
