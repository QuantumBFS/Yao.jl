using PkgBenchmark

current = BenchmarkConfig(id="transpose_storage", juliacmd=`julia -O3`)
baseline = BenchmarkConfig(id="master", juliacmd=`julia -O3`)
results = judge("YaoArrayRegister", current, baseline)
export_markdown("report.md", results)
