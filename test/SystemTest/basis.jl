"""
polar angle to vector.
"""
function polar2vec(polar::Array{T,N}) where T, N
    r, theta, phi = polar
    vec = concatenate([(np.sin(theta) * cos(phi))[...,None], (sin(theta) * sin(phi))[...,None], cos(theta)[...,None]])*r
    return vec
end

"""
transform a vector to polar axis.
"""
function vec2polar(vec::Array{T,N}) where T, N
    r = norm(vec, axis=-1, keepdims=True)
    theta = arccos(vec[...,2:3]/r)
    phi = arctan2(vec[...,1:2], vec[...,1:1])
    res = concatenate([r, theta, phi], axis=-1)
    return res
end

"""
random measurement basis.

Args:
    num_bit (int): the number of bit.

Returns:
    2darray: first column is the theta angles, second column is the phi angles.
"""
function random_basis(rotblock::RotBlock)
    polars = randn(nqubit(rotblock), 3) |> vec2polar
    print(polars)
    polars[:,3] = mod(polars[:,3], pi)
    return polars[:,2:3]
end

"""
unit basis to polar angles
"""
function u2polar(vec::Array{Complex128, N})
    ratio = vec[1]/vec[0]
    theta = arctan(abs(ratio))*2
    phi = angle(ratio)
    return theta, phi
end

"""
polar angle to unit basis.
"""
function polar2u(polar)
    theta, phi = polar
    return np.array([np.cos(theta/2.)*np.exp(-1j*phi/2.), np.sin(theta/2.)*np.exp(1j*phi/2.)])
end

"""
random pauli matrix.
"""
function random_pauli(pure=True)
    vec = np.random.randn(4)
    if pure: vec[0] = 0
    vec/=np.linalg.norm(vec)
    return vec2s(vec)
end

"""
Transform a spin to a 4 dimensional vector, corresponding to s0,sx,sy,sz component.

Args:
    s (matrix): the 2 x 2 pauli matrix.
"""
s2vec(s) = [trace(si * s) for si in pauli_matrices]/2.0

"""
Transform a vector of length 3 or 4 to a pauli matrix.

Args:
    n (int): a 1-D array of length 3 or 4 to specify the `direction` of spin.
Returns:
    2 x 2 matrix.
"""
function vec2s(n)
    if len(n) > 4:
        raise Exception('length of vector %s too large.'%len(n))
    sl = ss[1:] if len(n) <= 3 else ss
    return reduce(lambda x,y:x+y, [si*ni for si,ni in zip(sl, n)])
end


