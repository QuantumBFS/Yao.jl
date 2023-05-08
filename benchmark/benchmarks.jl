using Yao
using Yao: YaoArrayRegister, YaoBlocks

module YaoArrayRegisterBenchmarks
include("../lib/YaoArrayRegister/benchmark/benchmarks.jl")
end

module YaoBlocksBenchmarks
include("../lib/YaoBlocks/benchmark/benchmarks.jl")
end

using BenchmarkTools
import .YaoArrayRegisterBenchmarks: SUITE as yarSUITE
import .YaoBlocksBenchmarks: SUITE as ybSUITE

const SUITE = BenchmarkGroup()
SUITE["YaoArrayRegister"] = yarSUITE
SUITE["YaoBlocks"] = ybSUITE
