using PkgBenchmark

current = BenchmarkConfig(id="multithreading", env = Dict("JULIA_NUM_THREADS"=>4), juliacmd=`julia -O3`)
baseline = BenchmarkConfig(id="master", env = Dict("JULIA_NUM_THREADS"=>1), juliacmd=`julia -O3`)
results = judge("YaoArrayRegister", current, baseline)
export_markdown("report.md", results)
