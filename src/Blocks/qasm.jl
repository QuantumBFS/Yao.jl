"""
## References
> Open Quantum Assembly Language
> Andrew W. Cross, Lev S. Bishop, John A. Smolin, Jay M. Gambetta
> January 10th, 2017
> https://arxiv.org/pdf/1707.03429.pdf

## Gramma
// comment
gate name(params) qargs
{
    body
}

## Command Table
u3, u2, u1
id, x, y, z, h, s, sdag, t, tdag
rx, ry, rz
cx, cy, cz, ch
ccx
crz, cu1, cu3

See Ref. 1 for detail

## Examples:
1. single qubit gate
// this is ok:
gate g a
{
    U(0,0,0) a;
}
// this is invalid:
gate g a
{
    U(0,0,0) a[0];
}

2. unitary subroutine

gate cu1(lambda) a,b
{
    U(0,0,theta/2) a;
    CX a,b;
    U(0,0,-theta/2) b;
    CX a,b;
    U(0,0,theta/2) b;
}
cu1(pi/2) q[0],q[1];

3. 4 qubit gates
gate g qb0,qb1,qb2,qb3
{
// body
}
qreg qr0[1];
qreg qr1[2];
qreg qr2[3];
qreg qr3[2];
g qr0[0],qr1,qr2[0],qr3; // ok
g qr0[0],qr2,qr1[0],qr3; // error!

4. barrier
The barrier instruction prevents optimizations from reordering gates across its source
line. For example,
CX r[0],r[1];
h q[0];
h s[0];
barrier r,q[0];
h s[0];
CX r[1],r[0];
CX r[0],r[1];

will prevent an attempt to combine the CNOT gates but will allow the pair of h s[0]; gates
to cancel.

## Yao to QASM
sequence, chain => gate func#(params...) reg

put(nbit, i=>G) => G reg[i]
control(nbit, cbits, ibits=>G)
"""
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

struct QASMStr <: AbstractBlock
    str::String
end

apply!(reg, ::QASMStr) = reg
qasm(qs::QASMStr, args...) = qs.str

qasm(blk::Daggered, args...) = qasm(blk |> parent) * " †"
qasm(blk::AbstractScale, args...) = String(factor(blk)) * " * " * qasm(blk |> parent)
qasm(blk::Union{CachedBlock, AbstractDiff}, args...) = ""

using Test
@testset "qasm basic" begin
    @test control(3, (1,3), 2=>Z) |> qasm == "ccz  reg[0], reg[2], reg[1]"
    @test control(3, (1,), 2=>X) |> qasm == "cx  reg[0], reg[1]"
    @test put(5, 2=>rot(X, 0.3)) |> qasm == "rx(0.3)  reg[1]"
    @test control(3, (1,), 2=>rot(X, 0.3)) |> qasm == "crx(0.3)  reg[0], reg[1]"
    @test put(5, 3=>X) |> qasm == "x  reg[2]"
    @test put(5, 3=>X) |> qasm == "x  reg[2]"
    @test put(5, 3=>I2) |> qasm == "id  reg[2]"
end
