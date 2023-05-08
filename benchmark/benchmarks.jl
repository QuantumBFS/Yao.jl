module BenchmarkUtils
    """
    Replace instances of, for example, `using YaoAPI` with `using Yao.YaoAPI`.
    """
    const libs = (:YaoAPI, :YaoArrayRegister, :YaoBlocks, :YaoSym)
    function replace_imports(ex)
        return _replace_imports(ex)
    end
    function _replace_imports(ex)
        if isa(ex, Expr) && ex.head == :using
            foreach(ex.args) do e
                if isa(e, Expr) && first(e.args) in libs
                    pushfirst!(e.args, :Yao)
                end
            end
        elseif isa(ex, Expr)
            map!(_replace_imports, ex.args, ex.args)
        end
        return ex
    end
end

module YaoArrayRegisterBenchmarks
    using ..BenchmarkUtils: replace_imports
    using Yao
    include(replace_imports, "../lib/YaoArrayRegister/benchmark/benchmarks.jl")
end

module YaoBlocksBenchmarks
    using ..BenchmarkUtils: replace_imports
    using Yao
    include(replace_imports, "../lib/YaoBlocks/benchmark/benchmarks.jl")
end

using BenchmarkTools
import .YaoArrayRegisterBenchmarks: SUITE as yarSUITE
import .YaoBlocksBenchmarks: SUITE as ybSUITE

const SUITE = BenchmarkGroup()
SUITE["YaoArrayRegister"] = yarSUITE
SUITE["YaoBlocks"] = ybSUITE
