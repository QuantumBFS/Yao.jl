# Benchmarks for 16-site gate construction

## Using Int64

  "Basic Gate" => 4-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Y" => Trial(257.354 μs)
	  "Z" => Trial(119.019 μs)
	  "X" => Trial(165.324 μs)
	  "X*v" => Trial(193.954 μs)
  "CZ Gate" => 3-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Diag-CZ" => Trial(27.302 μs)
	  "CZ" => Trial(158.209 μs)
	  "General-CZ" => Trial(2.790 ms)
  "CX Gate" => 3-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "PM-CNOT" => Trial(2.174 ms)
	  "CNOT" => Trial(144.640 μs)
	  "General-CNOT" => Trial(2.780 ms)
  "Toffoli Gate" => 2-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Toffoli" => Trial(1.890 ms)
	  "General-Toffoli" => Trial(5.285 ms)

## Using UInt64
  "Basic Gate" => 4-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Y" => Trial(30.408 ms)
	  "Z" => Trial(18.279 ms)
	  "X" => Trial(18.965 ms)
	  "X*v" => Trial(197.839 μs)
  "CZ Gate" => 3-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Diag-CZ" => Trial(28.288 μs)
	  "CZ" => Trial(243.573 μs)
	  "General-CZ" => Trial(2.768 ms)
  "CX Gate" => 3-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "PM-CNOT" => Trial(2.228 ms)
	  "CNOT" => Trial(331.409 μs)
	  "General-CNOT" => Trial(2.738 ms)
  "Toffoli Gate" => 2-element BenchmarkTools.BenchmarkGroup:
	  tags: []
	  "Toffoli" => Trial(1.945 ms)
	  "General-Toffoli" => Trial(5.255 ms)
