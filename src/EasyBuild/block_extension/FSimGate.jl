export FSimGate, fsim_block

"""
    FSimGate{T<:Number} <: PrimitiveBlock{2}

The two parameter `FSim` gate.

References
-------------------------
* Arute, Frank, et al. "Quantum supremacy using a programmable superconducting processor." Nature 574.7779 (2019): 505-510.
"""
mutable struct FSimGate{T<:Number} <: PrimitiveBlock{2}
    theta::T
    phi::T
end
YaoBlocks.nqudits(fs::FSimGate) = 2
YaoBlocks.print_block(io::IO, block::FSimGate) = print(io, "FSim(θ=$(block.theta), ϕ=$(block.phi))")

function Base.:(==)(fs1::FSimGate, fs2::FSimGate)
    return fs1.theta == fs2.theta && fs1.phi == fs2.phi
end

function YaoAPI.mat(::Type{T}, fs::FSimGate) where T
    θ, ϕ = fs.theta, fs.phi
    T[1 0          0          0;
     0 cos(θ)     -im*sin(θ) 0;
     0 -im*sin(θ) cos(θ)     0;
     0 0          0          exp(-im*ϕ)]
end

YaoAPI.iparams_eltype(::FSimGate{T}) where T = T
YaoAPI.getiparams(fs::FSimGate{T}) where T = (fs.theta, fs.phi)
function YaoAPI.setiparams!(fs::FSimGate{T}, θ, ϕ) where T
    fs.theta = θ
    fs.phi = ϕ
    return fs
end

YaoBlocks.@dumpload_fallback FSimGate FSimGate
YaoBlocks.Optimise.to_basictypes(fs::FSimGate) = fsim_block(fs.theta, fs.phi)

"""
    fsim_block(θ::Real, ϕ::Real)

The circuit representation of FSim gate.
"""
function fsim_block(θ::Real, ϕ::Real)
    if θ ≈ π/2
        return cphase(2,2,1,-ϕ)*SWAP*rot(kron(Z,Z), -π/2)*put(2,1=>phase(-π/4))
    else
        return cphase(2,2,1,-ϕ)*rot(SWAP,2*θ)*rot(kron(Z,Z), -θ)*put(2,1=>phase(θ/2))
    end
end

YaoPlots.get_brush_texts(c, b::FSimGate) = (c.gatestyles.g, "FSim($(YaoPlots.pretty_angle(b.theta)), $(YaoPlots.pretty_angle(b.phi)))")
