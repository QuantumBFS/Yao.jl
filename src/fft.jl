using Yao
using Compat.Test
using Yao.Blocks

using Yao.Intrinsics
using Yao.Registers: DefaultRegister

_Rk(k) = PhaseGate{:shift, Float64}(2π/(1<<k))
_iRk(k) = PhaseGate{:shift, Float64}(-2π/(1<<k))
_H(num_bit, k::Int) = KronBlock{num_bit, Complex128}([k], [HGate{Complex128}()])

function QIFFT(num_bit::Int)
    circuit = []
    for i = num_bit:-1:1
        push!(circuit, _H(num_bit, i))
        for j = i-1:-1:1
            push!(circuit, ControlBlock{num_bit}([j], _Rk(i-j+1), i))
        end
    end
    chain(circuit...)
end

function QFFT(num_bit::Int)
    circuit = []
    for i = 1:num_bit
        push!(circuit, _H(num_bit, i))
        for j = i+1:num_bit
            #push!(circuit, control_iRk(num_bit, i, j, j-i+1))
            push!(circuit, ControlBlock{num_bit}([i], _iRk(j-i+1), j))
        end
    end
    chain(circuit...)
end

qfft2fft(num_bit::Int) = chain([SwapBlock(i, num_bit-i+1) for i in 1:div(num_bit, 2)])
