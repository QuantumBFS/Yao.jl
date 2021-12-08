"""
    dump_gate(blk::AbstractBlock) -> Expr

convert a gate to a YaoScript expression for serization.
The fallback is `GateTypeName(fields...)`
"""
function dump_gate end

function dump_gate(blk::ConstantGate)
    Symbol("$(typeof(blk).name.name)"[1:end-4])
end

function dump_gate(blk::ControlBlock)
    pairs = [:($b => C($c)) for (b, c) in zip(blk.ctrl_locs, blk.ctrl_config)]
    :($(pairs...), $(blk.locs) => $(dump_gate(blk.content)))
end

function dump_gate(blk::ChainBlock)
    Expr(:block, [dump_gate(b) for b in blk]...)
end

function dump_gate(blk::RotationGate)
    :(rot($(dump_gate(blk.block)), $(tokenize_param(blk.theta))))
end

function dump_gate(blk::TimeEvolution)
    :(time($(tokenize_param(blk.dt))) => $(dump_gate(blk.H)))
end

function dump_gate(blk::PutBlock)
    :($(blk.locs) => $(dump_gate(blk.content)))
end

function dump_gate(blk::KronBlock{N}) where {N}
    if any(x -> nqubits(x) != 1, subblocks(blk))
        error("unsupported multi-qubit in kron while dumping to Yao script.")
    end
    if length(occupied_locs(blk)) == N
        :(kron($([dump_gate(blk[i]) for i = 1:N]...)))
    else
        :(($([:($i => $(dump_gate(g))) for (i, g) in blk]...),))
    end
end

function dump_gate(blk::RepeatedBlock)
    :(repeat($(blk.locs...)) => $(dump_gate(blk.content)))
end

function dump_gate(blk::Add)
    :(+($(dump_gate.(subblocks(blk))...)))
end

function dump_gate(blk::Daggered)
    :($(dump_gate(blk.content))')
end

function dump_gate(blk::CachedBlock)
    :(cache($(dump_gate(blk.content))))
end

function dump_gate(blk::Scale)
    :($(factor(blk)) * $(dump_gate(blk.content)))
end

function dump_gate(blk::Measure{N,M}) where {M,N}
    if blk.operator == ComputationalBasis()
        MOP = :(Measure)
    else
        MOP = :(Measure($(dump_gate(blk.operator))))
    end
    locs = blk.locations isa AllLocs ? :ALL : blk.locations
    if blk.postprocess isa NoPostProcess
        :($locs => $MOP)
    elseif blk.postprocess isa ResetTo
        :($locs => $MOP => resetto($(blk.postprocess.x...)))
    elseif blk.postprocess isa RemoveMeasured
        :($locs => $MOP => remove)
    end
end

function dump_gate(blk::Subroutine)
    :(focus($(blk.locs...)) => $(dump_gate(blk.content)))
end

tokenize_param(param::Number) = param

yaotoscript(block::AbstractBlock{N}) where {N} =
    Expr(:block, :(nqubits = $N), dump_gate(block)) |> rmlines
function yaotoscript(block::ChainBlock{N}) where {N}
    ex = dump_gate(block)
    Expr(:let, Expr(:block, :(nqubits = $N), :(version = "0.6")), ex)
end
yaotofile(filename::String, block) = write(filename, string(yaotoscript(block)))

macro dumpload_fallback(blocktype, fname)
    quote
        function YaoBlocks.dump_gate(blk::$(esc(blocktype)))
            vars = [getproperty(blk, x) for x in fieldnames($(esc(blocktype)))]
            Expr(:call, $(QuoteNode(fname)), vars...)
        end
        function YaoBlocks.gate_expr(::Val{$(QuoteNode(fname))}, args, info)
            Expr(:call, $(QuoteNode(fname)), render_arg.(args, Ref(info))...)
        end
    end
end
