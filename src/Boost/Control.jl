function mat(ctrl::ControlBlock{N, <:MatrixBlock{1}}) where N
    controlled_U1(N, mat(ctrl.block), [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addr)
end

for (GATE, APPLY, MAT) in zip([:XGate, :YGate, :ZGate], [:cxapply!, :cyapply!, :czapply!], [:cxgate, :cygate, :czgate])
    @eval function mat(ctrl::ControlBlock{N, <:$GATE, C, T}) where {N, C, T}
        $MAT(T, N, [ctrl.ctrl_qubits...], [ctrl.vals...], ctrl.addr)
    end
    @eval function apply!(reg::DefaultRegister, ctrl::ControlBlock{N, <:$GATE, 1, T}) where {N, T}
        state = reg.state |> matvec
        $APPLY(state, ctrl.ctrl_qubits..., ctrl.vals..., ctrl.addr)
        reg
    end
end
