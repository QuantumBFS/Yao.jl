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
module QASM

using Yao.Blocks
export qasm

addrs2str(addrs) = join(["reg[$(i-1)]" for i in addrs], ", ")
floats2str(params) = join(["$p" for p in params], ", ")
args2str(pcounts) = join(["p$i" for i=pcounts], ", ")

const qasm_var_count = 0

struct QASMIdDict
    data
end


function qasm_gengym(tag)
    global qasm_var_count
    join([tag, qasm_var_count], "_")
end

qasm(blk::PutBlock{N}) where N =
    "gate"
    qasm(blk.block) * " "

qasm(blk::PutBlock{N}, args...) where N = qasm(blk.block, args...) * "  " * addrs2str(blk.addrs)
qasm(blk::ControlBlock{N}, args...) where N = "C-" * qasm(blk.block, args...) * "  " * addrs2str(blk.addrs)

function qasm(blk::PutBlock)
    qasm(blk.block)
    " " * blk.addrs
end

qasm_genargs(n::Int) = [join(["reg", local_count]) for local_count in 0:(n-1)]

function _code_qasm(blk)
    gate_head = join(["gate", qasm_gengym(name(blk)), qasm_genargs(nqubits(blk))...], " ")
    gate_body = qasm(blk)
    gate_ex = join([gate_head, "{", gate_body, "}"], "\n")
    gate_ex
end

macro code_qasm(ex)
    quote
        _code_qasm(ex)
    end
end

# include("compile.jl")
# include("qasm_str.jl")

end
