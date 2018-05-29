# 3. measurement
export measure
measure(m::Int) = Measure{m}()

export measure_remove
measure_remove(m::Int) = MeasureAndRemove{m}()
