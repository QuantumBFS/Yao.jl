using Yao
using Yao.EasyBuild
using LinearAlgebra

function compare(n::Int, eps = 1e-8)
    h = Matrix(heisenberg(n))
    st0 = eigvecs(h)[:, 1]

    x = ArrayReg(st0)
    y = normalize!(ArrayReg(st0 + eps * rand(2^n)))
    obs = expect(chain(n, put(1=>X), put(2=>X)), x)
    obs_ = expect(chain(n, put(1=>X), put(2=>X)), y)
    1 - fidelity(x, y), abs(obs - obs_)/abs(obs)
end

function average(n::Int, eps)
    reduce(compare(n, eps) for _ in 1:100) do x, y
        x .+ y
    end ./ 100
end
