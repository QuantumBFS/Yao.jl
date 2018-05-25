export sx, sy, sz, i2

i2 = [1, 0, 0im, 1]
sx = [0, 1, 1, 0im]
sy = [0, -im, im, 0]
sz = [1, 0im, 0, -1]

export psi2prob
psi2prob(psi::Array) = real(conj(psi).*psi)
