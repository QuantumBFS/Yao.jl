export Wait

"""
    Wait{N, T} <: TrivialGate{N}
    Wait{N}(t)

Wait the experimental signals for time `t` (empty run).
"""
struct Wait{N, T} <: TrivialGate{N}
    t::T
    Wait{N}(t::T) where {N,T} = new{N, T}(t)
end
YaoAPI.print_block(io::IO, d::Wait) = print(io, "Wait → $(d.t)")

export EchoBlock
struct EchoBlock{N,OT<:IO} <: PrimitiveBlock{N}
    sym::Symbol
    io::OT
end

EchoBlock(nbits::Int, sym::Symbol) = EchoBlock{nbits, typeof(stdout)}(sym, stdout)
EchoBlock(nbits::Int) = EchoBlock(nbits, :ECHO)
EchoBlock() = nbits->EchoBlock(nbits)

_apply!(reg::AbstractRegister, ec::EchoBlock) = (println(ec.io, "apply!(::$(typeof(reg)), $(ec.sym))"); reg)
YaoAPI.mat(::Type{T}, ec::EchoBlock{N}) where {T,N} = (println(ec.io, "mat(::Type{$T}, $(ec.sym))"); IMatrix{1<<N}())
LinearAlgebra.ishermitian(ec::EchoBlock{N}) where N = (println(ec.io, "ishermitian($(ec.sym))"); true)
YaoAPI.isunitary(ec::EchoBlock{N}) where N = (println(ec.io, "isunitary($(ec.sym))"); true)
YaoAPI.isreflexive(ec::EchoBlock{N}) where N = (println(ec.io, "isreflexive($(ec.sym))"); true)
YaoAPI.getiparams(ec::EchoBlock{N}) where N = (println(ec.io, "getiparams($(ec.sym))");())
YaoBlocks.print_block(io::IO, ec::EchoBlock) = print(io, "EchoBlock($(ec.sym))")
