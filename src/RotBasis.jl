export RotBasis, randpolar, polar2u, u2polar, rot_basis

"""
    RotBasis{T} <: PrimitiveBlock{1, Complex{T}}

A special rotation block that transform basis to angle θ and ϕ in bloch sphere.
"""
mutable struct RotBasis{T} <: PrimitiveBlock{1, Complex{T}}
    theta::T
    phi::T
end

_make_rot_mat(I, block, theta) = I * cos(theta / 2) - im * sin(theta / 2) * block
# chain -> *
# mat(rb::RotBasis{T}) where T = mat(Ry(-rb.theta))*mat(Rz(-rb.phi))
function mat(x::RotBasis{T}) where T
    R1 = _make_rot_mat(IMatrix{2, Complex{T}}(), mat(Z), -x.phi)
    R2 = _make_rot_mat(IMatrix{2, Complex{T}}(), mat(Y), -x.theta)
    R2 * R1
end

==(rb1::RotBasis, rb2::RotBasis) = rb1.theta == rb2.theta && rb1.phi == rb2.phi

copy(block::RotBasis{T}) where T = RotBasis{T}(block.theta, block.phi)
dispatch!(block::RotBasis, params::Vector) = ((block.theta, block.phi) = params; block)

getiparams(rb::RotBasis) = (rb.theta, rb.phi)
function setiparams!(rb::RotBasis, θ::Real, ϕ::Real)
    rb.theta, rb.phi = θ, ϕ
    rb
end
niparams(::Type{<:RotBasis}) = 2
niparams(::RotBasis) = 2
render_params(r::RotBasis, ::Val{:random}) = rand()*π, rand()*2π

function print_block(io::IO, R::RotBasis)
    print(io, "RotBasis($(R.theta), $(R.phi))")
end

function hash(gate::RotBasis, h::UInt)
    hash(hash(gate.theta, gate.phi, objectid(gate)), h)
end

cache_key(gate::RotBasis) = (gate.theta, gate.phi)

rot_basis(num_bit::Int) = dispatch!(chain(num_bit, put(i=>RotBasis(0.0, 0.0)) for i=1:num_bit), randpolar(num_bit) |> vec)

"""
    u2polar(vec::Array) -> Array

transform su(2) state vector to polar angle, apply to the first dimension of size 2.
"""
function u2polar(vec::Vector)
    ratio = vec[2]/vec[1]
    [atan(abs(ratio))*2, angle(ratio)]
end

"""
    polar2u(vec::Array) -> Array

transform polar angle to su(2) state vector, apply to the first dimension of size 2.
"""
function polar2u(polar::Vector)
    theta, phi = polar
    [cos(theta/2)*exp(-im*phi/2), sin(theta/2)*exp(im*phi/2)]
end

u2polar(arr::Array) = mapslices(u2polar, arr, dims=[1])
polar2u(arr::Array) = mapslices(polar2u, arr, dims=[1])

"""
    randpolar(params::Int...) -> Array

random polar basis, number of basis
"""
randpolar(params::Int...) = rand(2, params...)*pi
