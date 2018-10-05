# Yao.jl v0.3.0-DEV Release Notes
## New Features
* `dispatch!!` for dispatching vector parameters by poping out elements.
* interfaces `iparameters` (return tuple), `setiparameters!` and `niparameters` for net parameters.
* `PauliString` and `Scale{X}` blocks.

## API Changes
* `measure!` and `measure_and_remove!` now returns measure results only.
* `CompositeBlock` now refers to multi-sibling nodes only, and single sibling node is refered as `AbstractContainer`. The block type tree
```julia
AbstractBlock
    AbstractMeasure
        Measure
        MeasureAndRemove
    FunctionBlock
    MatrixBlock
        AbstractContainer
            Concentrator
            ControlBlock
            Diff
            PutBlock
            RepeatedBlock
            TagBlock
                CachedBlock
                Daggered
                Scale
        CompositeBlock
            ChainBlock
            KronBlock
            PauliString
            Roller
        PrimitiveBlock
            ConstantGate
                CNOTGate
                HGate
                I2Gate
                P0Gate
                P1Gate
                PdGate
                PuGate
                ToffoliGate
                XGate
                YGate
                ZGate
            GeneralMatrixGate
            MathBlock
            PhaseGate
            ReflectBlock
            RotationGate
            ShiftGate
            Swap
            TimeEvolution
    Sequential
```

## Deprecations
* `hasparameters` is deprecated, use `iparameters(blk) > 0` (for intrinsic) or `nparameters(blk) > 0` instead.
* blocks -> subblocks, which will return tuple if the block is not mutable, otherwise a vector (e.g. composite blocks like `ChainBlock`).
* `isprimitive` is deprecated, use `block isa PrimitiveBlock` instead.
