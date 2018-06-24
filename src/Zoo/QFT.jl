CRk(i::Int, j::Int, k::Int) = control([i, ], j=>shift(-2π/(1<<k)))
CRot(n::Int, i::Int) = chain(i==j ? put(i=>H) : CRk(j, i, j-i+1) for j = i:n)
QFT(n::Int) = chain(n, CRot(n, i) for i = 1:n)
