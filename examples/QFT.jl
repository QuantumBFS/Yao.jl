using Yao
function IQFT(n::Int)
    circuit = []
    for i = n:-1:1
        push!(circuit, kron(n, i=>H))
        for j = i-1:-1:1
            k = i - j + 1
            push!(circuit, control(n, [j, ], i=>shift(2π/(1<<k))))
        end
    end
    chain(n, circuit)
end

function QFT(n::Int)
    circuit = chain(n)
    for i = 1:n - 1
        push!(circuit, i=>H)
        g = chain(
            control([i, ], j=>shift(-2π/(1<< (j - i + 1))))
            for j = i+1:n
        )
        push!(circuit, g)
    end
    push!(circuit, n=>H)
end

num_bit = 5
ifftblock = IQFT(num_bit)
fftblock = QFT(num_bit)
reg = rand_state(num_bit)
rv = copy(statevec(reg))

using Compat.Test
@test Matrix(mat(chain(3, IQFT(3), QFT(3)))) ≈ eye(1<<3)

# test ifft
println(ifftblock)
reg1 = copy(reg) |>ifftblock

print(reg1)
# permute lines (Manually)
qkv = vec(permutedims(reshape(statevec(reg1), fill(2, num_bit)...), collect(num_bit:-1:1)))
kv = ifft(rv)*sqrt(length(rv))
@test qkv ≈ kv

# test fft
reg.state[:] = vec(permutedims(reshape(statevec(reg), fill(2, num_bit)...), collect(num_bit:-1:1)))
reg2 = copy(reg) |> fftblock
kv = fft(rv)/sqrt(length(rv))
@test statevec(reg2) ≈ kv
#=
@compose 3 begin
    1 => X
    @control 2 1=>X
    3 => Y
end
=#
