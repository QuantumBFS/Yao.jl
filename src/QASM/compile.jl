using Yao
using Yao.Blocks

function Base.show(io::IO, ::MIME"qasm/open", blk::AbstractBlock)
    qcode = qasm(blk)
    println(io, "OPENQASM 2.0")
    maincode = pop!(qcode, "main")
    for k in keys
        println(io, qcode)
    end
    println(io, maincode)
end

######################## Basic Buiding Blocks ########################
const BASIC_1GATES = [:X, :Y, :Z, :H, :S, :Sdag, :T, :Tdag]

addrs2str(addrs) = join(["reg[$(i-1)]" for i in addrs], ", ")
floats2str(params) = join(["$p" for p in params], ", ")
args2str(pcounts) = join(["p$i" for i=pcounts], ", ")

qasm(blk::PutBlock{N}, args...) where N = qasm(blk.block, args...) * "  " * addrs2str(blk.addrs)
qasm(blk::ControlBlock{N}, args...) where N = "C-" * qasm(blk.block, args...) * "  " * addrs2str(blk.addrs)

# u3, u2,
# cu1, cu3
# if statement

# x, y, z, h, s, sdag, t, tdag
# u1 == z
for G in BASIC_1GATES
    GT = Symbol(G, :Gate)
    g = G |> String |> lowercase
    @eval qasm(blk::$GT, args...) = "$($g)"
    @eval qasm(blk::PutBlock{<:Any, <:Any, <:$GT}, args...) where N = "$($g)  " * addrs2str(blk.addrs)
end

# cx, cy, cz, ch
for G in BASIC_1GATES[1:4]
    GT = Symbol(G, :Gate)
    g = G |> String |> lowercase
    @eval qasm(blk::ControlBlock{<:Any, <:$GT}, args...) where N = "c$($g)  " * addrs2str([blk.ctrl_qubits[1], blk.addrs[1]])
end

# rx, ry, rz
# crz, crx, cry
# ccx, ccy, ccz
for G in BASIC_1GATES[1:3]
    GT = Symbol(G, :Gate)
    g = G |> String |> lowercase
    @eval qasm(blk::ControlBlock{<:Any, <:RotationGate{<:Any, <:Any, <:$GT}}, args...) where N = "cr$($g)($(blk.block.theta))  " * addrs2str([blk.ctrl_qubits[1], blk.addrs[1]])
    @eval qasm(blk::PutBlock{<:Any, <:Any, <:RotationGate{<:Any, <:Any, <:$GT}}, args...) where N = "r$($g)($(blk.block.theta))  " * addrs2str(blk.addrs)
    @eval qasm(blk::ControlBlock{<:Any, <:$GT, 2}, args...) where N = "cc$($g)  " * addrs2str([blk.ctrl_qubits..., blk.addrs[1]])
end

# id
qasm(blk::I2Gate, args...) = "id"
qasm(blk::PutBlock{<:Any, <:Any, <:I2Gate}, args...) = "id  " * addrs2str(blk.addrs)

function qasm(blk::AbstractBlock, args...)
    typeof(blk).name
end

function qasm(blk::Union{ChainBlock, Sequential}, funcs=Dict{String, String}("main"=>""), fcount::Int=0, pcount::Int=0, level::Int=0)
    GNAME = "G$pcount"
    # however, we don't support function parameters for the moment.
    nparams = nparameters(blk)
    code = "gate $GNAME reg\n{\n"
    code *= join(["    "^(level+1) * qasm(b, funcs, fcount+1, pcount+nparams, level+1) for b in subblocks(blk)], "\n")
    code *= "\n}"
    funcs[GNAME] = code
    "$GNAME reg"
end
