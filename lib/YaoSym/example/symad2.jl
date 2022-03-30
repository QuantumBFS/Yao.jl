using Yao, Yao.EasyBuild, Test

@vars α β γ
c = chain(put(3, 2 => Rx(α)), control(3, 2, 1 => Ry(β)), put(3, (1, 2) => rot(kron(X, X), γ)))
h = heisenberg(3);
es = expect(h, zero_state(Basic, 3) => c)
gs = expect'(h, zero_state(Basic, 3) => c).second
assign = Dict(α => 0.5, β => 0.7, γ => 0.8)

cn = subs(Float64, c, assign...)
en = expect(h, zero_state(3) => cn)
gn = expect'(h, zero_state(3) => cn).second
es_ = subs(es, assign...)
gs_ = map(x -> subs(x, assign...), gs)
@test ComplexF64.(gs_) ≈ gn
@test ComplexF64(es_) ≈ en
