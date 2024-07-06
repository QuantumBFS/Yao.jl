# The following code is copied from Thebes.jl, which is a package for 3D plotting in Julia.
# Since Thebes.jl is not updated for a while, we need to update the code to make it work with the latest version of Luxor.jl.

module Thebes
using Luxor
struct Point3D
    x::Float64
    y::Float64
    z::Float64
end

mutable struct Projection
    U::Point3D     #
    V::Point3D     #
    W::Point3D     #
    ue::Float64    #
    ve::Float64    #
    we::Float64    #
    eyepoint::Point3D
    centerpoint::Point3D
    uppoint::Point3D
    perspective::Float64 #
end

function newprojection(ipos::Point3D, center::Point3D, up::Point3D, perspective=0.0)
    if iszero(ipos.x)
        ipos = Point3D(10e-9, ipos.y, ipos.z)
    end  
    if iszero(ipos.y)
        ipos = Point3D(ipos.x, 10e-9, ipos.z)
    end  
    if iszero(ipos.z)
        ipos = Point3D(ipos.x, ipos.y, 10e-9)
    end  

    # w is the line of sight
    W = Point3D(center.x - ipos.x, center.y - ipos.y, center.z - ipos.z)
    r = (W.x * W.x) + (W.y * W.y) + (W.z * W.z)
    if r < eps()
        @info("eye position and center are the same")
        
        W = Point3D(0.0, 0.0, 0.0)
    else
        # distancealise w to unit length
        rinv = 1 / sqrt(r)
        W = Point3D(W.x * rinv, W.y * rinv, W.z * rinv)
    end
    we = W.x * ipos.x + W.y * ipos.y + W.z * ipos.z # project e on to w
    U = Point3D(W.y * (up.z - ipos.z) - W.z * (up.y - ipos.y),      # u is at right angles to t - e
        W.z * (up.x - ipos.x) - W.x * (up.z - ipos.z),      # and w ., its' the pictures x axis
        W.x * (up.y - ipos.y) - W.y * (up.x - ipos.x))
    r = (U.x * U.x) + (U.y * U.y) + (U.z * U.z)

    if r < eps()
        @info("struggling to make a valid projection with these parameters")
        U = Point3D(0.0, 0.0, 0.0)
    else
        rinv = 1 / sqrt(r) # distancealise u
        U = Point3D(U.x * rinv, U.y * rinv, U.z * rinv)
    end

    ue = U.x * ipos.x + U.y * ipos.y + U.z * ipos.z # project e onto u

    V = Point3D(U.y * W.z - U.z * W.y, # v is at right angles to u and w
        U.z * W.x - U.x * W.z, # it's the world's y axis
        U.x * W.y - U.y * W.x)

    ve = V.x * ipos.x + V.y * ipos.y + V.z * ipos.z # project e onto v

    Projection(U, V, W, ue, ve, we, ipos, center, up, perspective)
end

function project(proj::Projection, P::Point3D)
    # use default value for perspectiveness if not specified
    r = proj.W.x * P.x + proj.W.y * P.y + proj.W.z * P.z - proj.we
    if r < eps()
        # "point $P is behind eye"
        result = nothing
    else
        if proj.perspective == 0.0
            depth = 1
        else
            depth = proj.perspective * (1 / r)
        end
        uq = depth * (proj.U.x * P.x + proj.U.y * P.y + proj.U.z * P.z - proj.ue)
        vq = depth * (proj.V.x * P.x + proj.V.y * P.y + proj.V.z * P.z - proj.ve)
        result = Point(uq, -vq) # because Y is down the page in Luxor (?!)
    end
    return result
end

function eyepoint(pt::Point3D)
    return newprojection(pt, Point3D(0, 0, 0), Point3D(0, 0, 1))
end

function Luxor.distance(p1::Point3D, p2::Point3D)
    sqrt((p2.x - p1.x)^2 + (p2.y - p1.y)^2 + (p2.z - p1.z)^2)
end

end