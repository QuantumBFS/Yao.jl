# This part declares factory functions for constructing composite blocks

function parse_block(n::Int, x::Function)
    x(n)
end

function parse_block(n::Int, x::MatrixBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    x
end

parse_block(n::Int, x::AbstractBlock) = x

# 2. composite blocks
# 2.1 chain block
export chain

"""
    chain([T], n::Int) -> ChainBlock
    chain([n], blocks) -> ChainBlock
    chain(blocks...) -> ChainBlock

Returns a `ChainBlock`. This factory method can be called lazily if you
missed the total number of qubits.

This chains several blocks with the same size together.
"""
function chain end
chain(::Type{T}, n::Int) where T = ChainBlock{n, T}(MatrixBlock[])
chain(n::Int) = chain(DefaultType, n)
chain() = n -> chain(n)

function chain(n::Int, blocks...,)
    ChainBlock([parse_block(n, each) for each in blocks])
end

chain(blocks...,) = n -> chain(n, blocks...,)

function chain(n::Int, blocks)
    ChainBlock([parse_block(n, each) for each in blocks])
end

function chain(n::Int, f::Function)
    ChainBlock([f(n)])
end

function chain(blocks::MatrixBlock...,)
    ChainBlock(blocks...,)
end

chain(blocks) = n -> chain(n, blocks)

# 2.2 add block
export add

"""
    add([T], n::Int) -> AddBlock
    add([n], blocks) -> AddBlock
    add(blocks...) -> AddBlock

Returns a `AddBlock`. This factory method can be called lazily if you
missed the total number of qubits.

This adds several blocks with the same size together.
"""
function add end
add(::Type{T}, n::Int) where T = AddBlock{n, T}(MatrixBlock[])
add(n::Int) = add(DefaultType, n)
add() = n -> add(n)

function add(n::Int, blocks...,)
    AddBlock([parse_block(n, each) for each in blocks])
end

add(blocks...,) = n -> add(n, blocks...,)

function add(n::Int, blocks)
    AddBlock([parse_block(n, each) for each in blocks])
end

function add(n::Int, f::Function)
    AddBlock([f(n)])
end

function add(blocks::MatrixBlock...,)
    AddBlock(blocks...,)
end

add(blocks) = n -> add(n, blocks)

# 2.2 kron block
import Base: kron

"""
    kron([total::Int, ]block0::Pair, blocks::Union{MatrixBlock, Pair}...,) -> KronBlock{total}

create a [`KronBlock`](@ref) with a list of blocks or tuple of heads and blocks.
If total is not provided, return a lazy constructor.

## Example
```@example
kron(4, 1=>X, 3=>Z, 4=>Y)
```
This will automatically generate a block list looks like
```
1 -- [X] --
2 ---------
3 -- [Z] --
4 -- [Y] --
```
"""
kron(total::Int, blocks::Pair{Int, <:MatrixBlock}...,) = KronBlock{total}(blocks...,)
function kron(total::Int, blocks::MatrixBlock...,)
    sum(nqubits, blocks) == total || throw(AddressConflictError("Size of blocks does not match total size."))
    KronBlock(blocks)
end
kron(total::Int, blocks::Base.Generator) = kron(total, blocks...)

kron(blocks::MatrixBlock...,) = N->kron(N, blocks...)
kron(blocks::Pair{Int, <:MatrixBlock}...,) = N->kron(N, blocks...)
kron(blocks::Base.Generator) = N->kron(N, blocks)

export put
"""
    put([total::Int, ]pa::Pair) -> PutBlock{total}

put a block at the specific position(s), can be lazy constructed.
"""
put(total::Int, pa::Pair{NTuple{M, Int}, <:AbstractBlock}) where M = PutBlock{total}(pa.second, pa.first)
put(total::Int, pa::Pair{Int, <:AbstractBlock}) = PutBlock{total}(pa.second, (pa.first,))
put(pa::Pair) = total->put(total, pa)

# 2.3 control block

export C, control, cnot

decode_sign(ctrls::Int...,) = ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2)

"""
    control([total], controls, target) -> ControlBlock

Constructs a [`ControlBlock`](@ref)
"""
function control end

function control(total::Int, controls, target::Pair)
    ControlBlock{total}(decode_sign(controls...,)..., target.second, (target.first...,))
end

function control(controls, target)
    total->ControlBlock{total}(decode_sign(controls...,)..., target.second, (target.first...,))
end

function control(controls)
    function _control(x::Pair)
        total->ControlBlock{total}(decode_sign(controls...,)..., x.second, (x.first...,))
    end
end

function C(controls::Int...,)
    function _C(x::Pair{I, BT}) where {I, BT <: MatrixBlock}
        total->ControlBlock{total}(decode_sign(controls...,)..., x.second, (x.first...,))
    end
end

cnot(nbit::Int, cbit::Int, ibit::Int) = control(nbit, cbit, ibit=>X)
cnot(cbit::Int, ibit::Int) = nbit->cnot(nbit, cbit, ibit)

# 2.4 roller

export roll, rollrepeat

"""
    rollrepeat([n::Int,] block::MatrixBlock) -> Roller{n}

Construct a [`Roller`](@ref) block, which is a faster than [`KronBlock`](@ref) to calculate
similar small blocks tile on the whole address.
"""
function rollrepeat end
rollrepeat(n::Int, block::MatrixBlock) = Roller{n}(block)
rollrepeat(block::MatrixBlock) = n->rollrepeat(n, block)

"""
    roll([n::Int, ], blocks...,) -> Roller{n}

Construct a [`Roller`](@ref) block, which is a faster than [`KronBlock`](@ref) to calculate
similar small blocks tile on the whole address.
"""
function roll end

roll(blocks...,) = n->roll(n, blocks...,)
roll(itr) = n->roll(n, itr)

roll(n::Int, blocks...,) = roll(n, blocks)

function roll(n::Int, blocks::MatrixBlock...,)
    sum(nqubits, blocks) == n || throw(AddressConflictError("Size of blocks does not match total size."))
    Roller(blocks...,)
end

function roll(n::Int, a::Pair, blocks...,)
    roll(n, (a, blocks...,))
end

function roll(n::Int, itr)
    first(itr) isa Pair || throw(ArgumentError("Expect a Pair"))

    curr_head = 1
    list = []
    for each in itr
        if each isa MatrixBlock
            push!(list, each)
            curr_head += nqubits(each)
        elseif each isa Pair{Int, <:MatrixBlock}
            line, b = each
            k = line - curr_head

            k > 0 && push!(list, kron(k, i=>I2 for i=1:k))
            push!(list, b)
            curr_head = line + nqubits(b)
        end
    end

    k = n - curr_head + 1
    k > 0 && push!(list, kron(k, i=>I2 for i=1:k))

    sum(nqubits, list) == n || throw(ErrorException("number of qubits mismatch"))
    Roller(list...,)
end

# 2.5 repeat

import Base: repeat

"""
    repeat([n::Int,] x::MatrixBlock, [addrs]) -> RepeatedBlock{n}

Construct a [`RepeatedBlock`](@ref), if n (the number of qubits) not supplied, using lazy evaluation.
If addrs not supplied, blocks will fill the qubit space.
"""
repeat(n::Int, x::MatrixBlock, addrs) = RepeatedBlock{n}(x, (addrs...,))
repeat(n::Int, x::MatrixBlock) = RepeatedBlock{n}(x)
repeat(x::MatrixBlock, params...,) = n->repeat(n, x, params...,)

export concentrate

"""
    concentrate(nbit::Int, block::AbstractBlock, addrs) -> Concentrator{nbit}

concentrate blocks on serveral addrs.
"""
concentrate(nbit::Int, block::AbstractBlock, addrs) = Concentrator{nbit}(block, [addrs...])

export paulistring

"""
    paulistring([n], blocks::PauliGate...) -> PauliString
    paulistring([n], blocks::Pair{Int, PauliGate}...) -> PauliString

Returns a `PauliString`. This factory method can be called lazily if you
missed the total number of qubits.

This krons several pauli gates, either dict (more flexible) like input and chain like input are allowed.
i.e. paulistring(3, X, Y, Z) is equivalent to paulistring(3, 1=>X, 2=>Y, 3=>Z)
"""
function paulistring end
paulistring(nbit::Int, blocks::AbstractVector{<:PauliGate}) = nbit == length(blocks) ? PauliString(blocks) : throw(QubitMismatchError("paulistring parameter n should match the number of pauli gates!"))
paulistring(nbit::Int, blocks::PauliGate...,) = paulistring(nbit, PauliGate{promote_type([datatype(b) for b in blocks]...)}[blocks...])
paulistring(nbit::Int) = paulistring(nbit, PauliGate{ComplexF64}[I2 for i=1:nbit])

function paulistring(nbit::Int, pairs::Pair{Int, <:PauliGate}...,)
    blocks = PauliGate{promote_type([datatype(b.second) for b in pairs]...)}[I2 for i=1:nbit]
    for pair in pairs
        blocks[pair.first] = pair.second
    end
    paulistring(nbit, blocks)
end

paulistring(blocks...,) = N->paulistring(N, blocks...,)


export timeevolve
"""
    timeevolve([block::MatrixBlock], t::Real) -> TimeEvolution

Make a time machine! If block is not provided, it will become lazy.
"""
function timeevolve end
timeevolve(block::MatrixBlock, t::Number) = TimeEvolution(block, t)
timeevolve(t::Number) = block -> TimeEvolution(block, t)
