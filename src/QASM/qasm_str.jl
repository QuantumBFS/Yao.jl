struct QASMStr <: AbstractBlock
    str::String
end

macro qasm_str(s::String)
    QASMStr(s)
end

apply!(reg, ::QASMStr) = reg
qasm(qs::QASMStr, args...) = qs.str

qasm(blk::Daggered, args...) = qasm(blk |> parent) * " †"
qasm(blk::AbstractScale, args...) = String(factor(blk)) * " * " * qasm(blk |> parent)
qasm(blk::Union{CachedBlock, AbstractDiff}, args...) = ""

# NOTE: this is just mock one, but this will be useful when we start to use a real openqasm backend
macro code_qasm(ex)
    quote
        qasm($(ex))
    end
end
