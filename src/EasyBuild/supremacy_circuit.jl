export rand_supremacy2d

# control-Z entangler.
cz_entangler(n::Int, pairs) = chain(n, control(n, [ctrl], target=>Z) for (ctrl, target) in pairs)

"""
    rand_supremacy2d(nx::Int, ny::Int, depth::Int) -> AbstactBlock

The circuit proposed for realizing quantum supermacy in a near-term device.

References
-------------------------------
* Boixo, Sergio, et al. "Characterizing quantum supremacy in near-term devices." Nature Physics 14.6 (2018): 595-600.

!!! note

    Some restrictions are loosed, please check this circuit carefully.
"""
function rand_supremacy2d(nx::Int, ny::Int, depth::Int)
    nbits = nx*ny
    entanglers = map(pair->cz_entangler(nbits, pair), pair_supremacy(nx, ny))
    gateset = [ConstGate.T, SqrtX, SqrtY]
    c = chain(nbits, repeat(nbits, H, 1:nbits))
    pre_occ = (1:nbits...,)
    pre_gates = Vector{PrimitiveBlock}(fill(H,nbits))
    hastgate = zeros(Bool, nbits)
    for i=1:depth-2
        ent = entanglers[mod1(i,length(entanglers))]
        unit = chain(nbits, [ent])
        occ = occupied_locs(ent)
        for loc in setdiff(pre_occ, occ)
            g1 = hastgate[loc] ? rand(setdiff(gateset, (pre_gates[loc],))) : (hastgate[loc]=true; T)
            push!(unit, put(nbits, loc=>g1))
            pre_gates[loc] = g1
        end
        pre_occ = occ
        push!(c, unit)
    end
    depth!=1 && push!(c, repeat(nbits, H, 1:nbits))
    return c
end

# obtain supremacy pairing patterns
function pair_supremacy(nx::Int, ny::Int; periodic=false)
    Kx = [0.25 0.5; 0.25 -0.5]
    Ky = [0.5 0.25; -0.5 0.25]
    out = Vector[]
    li = LinearIndices((nx, ny))

    for (dx, dy, isxdirection) in [(2,0,true), (0,0,true), (0,3,false), (0,1,false),
                                    (3,0,true), (1,0,true), (0,0,false), (0,2,false)]
        res = Pair{Int, Int}[]
        for i = 1:nx, j=1:ny
            if (periodic || (isxdirection ? i<nx : j<ny)) && all(mod.((isxdirection ? Kx : Ky)*[i-dx-1, j-dy-1], 1) .≈ 0)
                i_ = isxdirection ? mod1(i+1, nx) : i
                j_ = isxdirection ? j : mod1(j+1, ny)
                push!(res, li[i, j] => li[i_, j_])
            end
        end
        push!(out, res)
    end

    return out
end